#pragma once

#include <QByteArray>
#include <QFile>
#include <QString>
#include <QStringList>

/// Minimal zip reader/writer for Modern reClock theme files (.zip).
/// Zip format: local file headers + data + central directory + EOCD.
/// Currently uses STORED (no compression). CRC32 via zlib.
struct MrtArchiveEntry {
    QString name;
    QByteArray data;
};

class MrtArchive {
public:
    // ===== READ =====
    /// Read a .zip theme file, extract all entries
    static QList<MrtArchiveEntry> read(const QString &filePath);

    /// Read a single file from the archive
    static QByteArray readSingle(const QString &filePath, const QString &entryName);

    // ===== WRITE =====
    /// Write a .zip theme file from entries (STORED, no compression)
    static bool write(const QString &filePath, const QList<MrtArchiveEntry> &entries);

private:
    // Zip local file header signature: 0x04034b50
    // Zip central directory signature: 0x02014b50
    // Zip end of central directory:    0x06054b50
    static constexpr quint32 LOCAL_HEADER_SIG  = 0x04034b50;
    static constexpr quint32 CENTRAL_HEADER_SIG = 0x02014b50;
    static constexpr quint32 EOCD_SIG           = 0x06054b50;

    static quint32 crc32(const QByteArray &data);
    static quint16 dosTime();
    static quint16 dosDate();
};
