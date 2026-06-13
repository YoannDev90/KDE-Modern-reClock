#pragma once

#include <QObject>
#include <QAbstractListModel>
#include <QDateTime>
#include <QVector>

struct LogEntry {
    QDateTime timestamp;
    QString category; // "clock", "timezone", "wallpaper", "config", "theme", "system"
    QString level;    // "debug", "info", "warn", "error"
    QString message;
};

class Logger;
class LogModel : public QAbstractListModel {
    Q_OBJECT
    friend class Logger;
public:
    enum Roles {
        TimestampRole = Qt::UserRole + 1,
        CategoryRole,
        LevelRole,
        MessageRole
    };

    explicit LogModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addEntry(const LogEntry& entry);
    void clear();

private:
    QVector<LogEntry> m_entries;
    int m_maxEntries = 500;
};

class Logger : public QObject {
    Q_OBJECT
    Q_PROPERTY(LogModel* model READ model CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int maxEntries READ maxEntries WRITE setMaxEntries NOTIFY maxEntriesChanged)
    Q_PROPERTY(QString logLevel READ logLevel WRITE setLogLevel NOTIFY logLevelChanged)
public:
    explicit Logger(QObject* parent = nullptr);

    LogModel* model() const { return m_model; }
    int count() const { return m_model->rowCount(); }
    int maxEntries() const { return m_maxEntries; }
    void setMaxEntries(int max) { m_maxEntries = max; m_model->m_maxEntries = max; emit maxEntriesChanged(); }

    QString logLevel() const { return m_logLevel; }
    void setLogLevel(const QString& level) { m_logLevel = level; emit logLevelChanged(); }

    /// Log a message: category = "clock"|"timezone"|"wallpaper"|"config"|"theme"|"system"
    /// level = "debug"|"info"|"warn"|"error"
    Q_INVOKABLE void log(const QString& category, const QString& level, const QString& message);

    /// Convenience methods
    Q_INVOKABLE void debug(const QString& category, const QString& message);
    Q_INVOKABLE void info(const QString& category, const QString& message);
    Q_INVOKABLE void warn(const QString& category, const QString& message);
    Q_INVOKABLE void error(const QString& category, const QString& message);

    /// Clear all entries
    Q_INVOKABLE void clear();

    /// Export as plain text
    Q_INVOKABLE QString exportText() const;

    /// Fetch filtered Plasma Shell logs from journalctl (synchronous)
    Q_INVOKABLE QString fetchPlasmaLogs(int lines = 200) const;

    /// Fetch Plasma Shell logs asynchronously. Emits plasmaLogsFetched() when done.
    Q_INVOKABLE void fetchPlasmaLogsAsync(int lines = 200);

    /// Export all log entries to a file in plain text format.
    /// Returns true on success.
    Q_INVOKABLE bool exportLogsToFile(const QString& filePath) const;

signals:
    void plasmaLogsFetched(const QString& result);
    void countChanged();
    void maxEntriesChanged();
    void logLevelChanged();

private:
    bool shouldLog(const QString& level) const;
    LogModel* m_model;
    int m_maxEntries = 500;
    QString m_logLevel = "debug"; // debug|info|warn|error
};
