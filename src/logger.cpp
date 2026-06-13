#include "logger.h"
#include <QDateTime>
#include <QTimeZone>

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
        beginRemoveRows(QModelIndex(), 0, m_entries.size() - m_maxEntries - 1);
        m_entries.remove(0, m_entries.size() - m_maxEntries + 1);
        endRemoveRows();
    }
    beginInsertRows(QModelIndex(), m_entries.size(), m_entries.size());
    m_entries.append(entry);
    endInsertRows();
}

void LogModel::clear() {
    if (m_entries.isEmpty()) return;
    beginResetModel();
    m_entries.clear();
    endResetModel();
}

// ===== Logger =====

Logger::Logger(QObject* parent)
    : QObject(parent), m_model(new LogModel(this)) {}

void Logger::log(const QString& category, const QString& level, const QString& message) {
    LogEntry entry;
    entry.timestamp = QDateTime::currentDateTime();
    entry.category = category;
    entry.level = level;
    entry.message = message;
    m_model->addEntry(entry);
    emit countChanged();
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
