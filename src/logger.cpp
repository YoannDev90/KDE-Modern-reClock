#include "logger.h"
#include <QDateTime>
#include <QFile>
#include <QTextStream>
#include <QTimeZone>
#include <QProcess>
#include <QThread>
#include <QStandardPaths>

// ===== LogModel =====

LogModel::LogModel(QObject* parent)
    : QAbstractListModel(parent) {}

int LogModel::rowCount(const QModelIndex& parent) const {
    Q_UNUSED(parent);
    return m_entries.size();
}

QVariant LogModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_entries.size())
        return QVariant();

    const LogEntry& e = m_entries.at(index.row());
    switch (role) {
    case TimestampRole: return e.timestamp;
    case CategoryRole:  return e.category;
    case LevelRole:     return e.level;
    case MessageRole:   return e.message;
    }
    return QVariant();
}

QHash<int, QByteArray> LogModel::roleNames() const {
    return {
        { TimestampRole, "timestamp" },
        { CategoryRole,  "category" },
        { LevelRole,     "level" },
        { MessageRole,   "message" }
    };
}

void LogModel::addEntry(const LogEntry& entry) {
    if (m_entries.size() >= m_maxEntries) {
        int removeCount = m_entries.size() - m_maxEntries + 1;
        qDebug() << "[ModernRecClock] LogModel: buffer full (" << m_maxEntries << "), removing" << removeCount << "old entries";
        beginRemoveRows(QModelIndex(), 0, removeCount - 1);
        m_entries.remove(0, removeCount);
        endRemoveRows();
    }
    beginInsertRows(QModelIndex(), m_entries.size(), m_entries.size());
    m_entries.append(entry);
    endInsertRows();
}

void LogModel::clear() {
    if (m_entries.isEmpty()) {
        qDebug() << "[ModernRecClock] LogModel::clear — already empty";
        return;
    }
    qDebug() << "[ModernRecClock] LogModel::clear — removing" << m_entries.size() << "entries";
    beginResetModel();
    m_entries.clear();
    endResetModel();
}

// ===== Logger =====

Logger::Logger(QObject* parent)
    : QObject(parent), m_model(new LogModel(this)) {}

bool Logger::shouldLog(const QString& level) const {
    static const QStringList order = { QStringLiteral("debug"), QStringLiteral("info"), QStringLiteral("warn"), QStringLiteral("error") };
    int msgIdx = order.indexOf(level);
    int cfgIdx = order.indexOf(m_logLevel);
    if (msgIdx < 0) msgIdx = 0;
    if (cfgIdx < 0) cfgIdx = 0;
    return msgIdx >= cfgIdx;
}

void Logger::log(const QString& category, const QString& level, const QString& message) {
    if (!shouldLog(level)) return;
    LogEntry entry;
    entry.timestamp = QDateTime::currentDateTime();
    entry.category = category;
    entry.level = level;
    entry.message = message;
    m_model->addEntry(entry);
    emit countChanged();
    qDebug() << "[ModernRecClock]" << category << level << message;
}

void Logger::debug(const QString& category, const QString& message) {
    log(category, QStringLiteral("debug"), message);
}

void Logger::info(const QString& category, const QString& message) {
    log(category, QStringLiteral("info"), message);
}

void Logger::warn(const QString& category, const QString& message) {
    log(category, QStringLiteral("warn"), message);
}

void Logger::error(const QString& category, const QString& message) {
    log(category, QStringLiteral("error"), message);
}

void Logger::clear() {
    m_model->clear();
    emit countChanged();
}

QString Logger::exportText() const {
    QStringList lines;
    for (int i = 0; i < m_model->rowCount(); ++i) {
        QModelIndex idx = m_model->index(i);
        QString ts = m_model->data(idx, LogModel::TimestampRole).toDateTime().toString(QStringLiteral("hh:mm:ss.zzz"));
        QString cat = m_model->data(idx, LogModel::CategoryRole).toString();
        QString lvl = m_model->data(idx, LogModel::LevelRole).toString();
        QString msg = m_model->data(idx, LogModel::MessageRole).toString();
        lines.append(QStringLiteral("%1 [%2/%3] %4").arg(ts, cat.toUpper(), lvl.toUpper(), msg));
    }
    return lines.join(QStringLiteral("\n"));
}

QString Logger::fetchPlasmaLogs(int maxLines) const {
    QStringList noiseFilters = {
        QStringLiteral("propertyCache.append"),
        QStringLiteral("overrides a member of the base object"),
        QStringLiteral("StackingOrder is overridden"),
        QStringLiteral("Could not find required file"),
        QStringLiteral("Setting initial properties failed"),
        QStringLiteral("Created graphical object was not placed"),
        QStringLiteral("QML SimpleKCM"),
        QStringLiteral("QObject::disconnect: Unexpected nullptr"),
        QStringLiteral("QQmlExpression"),
        QStringLiteral("non-bindable properties"),
        QStringLiteral("SimpleKCM_QMLTYPE"),
        QStringLiteral("Binding loop detected"),
    };

    auto filterOutput = [&](const QString& output) -> QString {
        QStringList lines = output.split(QStringLiteral("\n"));
        QStringList filtered;
        for (const QString& line : lines) {
            if (line.trimmed().isEmpty())
                continue;
            bool isNoise = false;
            for (const QString& f : noiseFilters) {
                if (line.contains(f)) { isNoise = true; break; }
            }
            if (!isNoise)
                filtered.append(line);
        }
        return filtered.isEmpty() ? QString() : filtered.join(QStringLiteral("\n"));
    };

    auto runJournal = [&](const QStringList& args) -> QString {
        QProcess proc;
        proc.setProgram(QStringLiteral("journalctl"));
        proc.setArguments(args);
        proc.start();
        if (!proc.waitForFinished(5000))
            return QString();
        QString output = QString::fromLocal8Bit(proc.readAllStandardOutput());
        if (output.trimmed().isEmpty())
            return QString();
        return filterOutput(output);
    };

    QString n = QString::number(maxLines);

    // Strategy 1: user journal + _COMM + recent
    QStringList a1;
    a1 << QStringLiteral("--user") << QStringLiteral("--no-pager") << QStringLiteral("--output=short-iso")
       << QStringLiteral("-n") << n << QStringLiteral("--since") << QStringLiteral("-30min")
       << QStringLiteral("_COMM=plasmashell");
    QString r = runJournal(a1);
    if (!r.isEmpty()) return r;

    // Strategy 2: system journal + _COMM + recent
    QStringList a2;
    a2 << QStringLiteral("--no-pager") << QStringLiteral("--output=short-iso")
       << QStringLiteral("-n") << n << QStringLiteral("--since") << QStringLiteral("-30min")
       << QStringLiteral("_COMM=plasmashell");
    r = runJournal(a2);
    if (!r.isEmpty()) return r;

    // Strategy 3: user journal + keyword + recent
    QStringList a3;
    a3 << QStringLiteral("--user") << QStringLiteral("--no-pager") << QStringLiteral("--output=short-iso")
       << QStringLiteral("-n") << n << QStringLiteral("--since") << QStringLiteral("-30min")
       << QStringLiteral("plasmashell");
    r = runJournal(a3);
    if (!r.isEmpty()) return r;

    // Strategy 4: system journal + _COMM, no time limit
    QStringList a4;
    a4 << QStringLiteral("--no-pager") << QStringLiteral("--output=short-iso")
       << QStringLiteral("-n") << n << QStringLiteral("_COMM=plasmashell");
    r = runJournal(a4);
    if (!r.isEmpty()) return r;

    return QStringLiteral("(no plasmashell logs found)");
}

void Logger::fetchPlasmaLogsAsync(int lines) {
    QThread* thread = QThread::create([this, lines]() {
        QString result = fetchPlasmaLogs(lines);
        QMetaObject::invokeMethod(this, [this, result]() {
            emit plasmaLogsFetched(result);
        }, Qt::QueuedConnection);
    });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    thread->start();
}

bool Logger::exportLogsToFile(const QString& filePath) const {
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qDebug() << "[ModernRecClock] Logger::exportLogsToFile FAILED to open" << filePath;
        return false;
    }
    QTextStream out(&file);
    out << "═══ Modern reClock Log Export ═══\n";
    out << "Generated: " << QDateTime::currentDateTime().toString(Qt::ISODate) << "\n";
    out << "Entries: " << m_model->rowCount() << "\n\n";
    out << exportText() << "\n";
    out << "═══ End of Export ═══\n";
    file.close();
    qDebug() << "[ModernRecClock] Logger::exportLogsToFile →" << filePath << "(" << m_model->rowCount() << "entries)";
    return true;
}
