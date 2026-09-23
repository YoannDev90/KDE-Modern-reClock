#pragma once

#include <QAbstractListModel>
#include <QColor>
#include <QDateTime>
#include <QLocale>
#include <QStringList>
#include <QTimer>
#include <QVariantMap>
#include <QVector>

// All-in-one clock engine. Owns the time itself, the formatting, the element
// order and the per-element style. QML stays purely declarative: it only
// pushes the plasmoid configuration and renders the model roles.
class ClockModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        TextRole = Qt::UserRole + 1,
        FontRole,
        SizeRole,
        SpacingRole,
        BoldRole,
        ColorRole,
        VisibleRole
    };

    explicit ClockModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // QML pushes the whole plasmoid.configuration in one call.
    Q_INVOKABLE void setConfig(const QVariantMap& config);
    Q_INVOKABLE void setThemeColors(const QColor& text, const QColor& bg);
    Q_INVOKABLE void setWallpaperColor(const QColor& color);
    Q_INVOKABLE void refresh();

private:
    struct Element {
        QString type;            // "day" | "date" | "time" | "timezone"
        bool visible = true;
        QString text;
        QString fontFamily;
        int fontSize = 19;
        int spacing = 3;
        bool bold = false;
        QColor color;
    };

    void rebuildElements();
    void recomputeElements();
    void recomputeTexts();
    void scheduleNextTick();
    void tick();

    QString dayText() const;
    QString dateText() const;
    QString timeText() const;
    QString timezoneText() const;
    QString currentTimeFormat() const;
    QString timezoneTimeFormat() const;
    QString formatDate(const QDateTime& dt, const QString& format, bool uppercase) const;
    QString formatTime(const QDateTime& dt, const QString& format) const;
    QColor resolveColor(const QString& type, const QColor& custom) const;
    QLocale effectiveLocale() const;
    QDateTime currentDateTime() const;

    QVector<Element> m_elements;
    QStringList m_order;

    // Raw configuration cache (already defaulted in setConfig)
    QVariantMap m_cfg;

    // Derived quick-access values
    QString m_colorMode = "custom";
    QColor m_systemTextColor;
    QColor m_systemBgColor;
    QColor m_wallpaperColor;
    bool m_hasWallpaperColor = false;

    QDateTime m_now;
    bool m_usesSeconds = false;

    QTimer m_timer;
};