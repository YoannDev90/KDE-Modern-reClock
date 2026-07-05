#include "mrtarchive.h"

#include <QDataStream>
#include <QDateTime>
#include <QDebug>
#include <zlib.h>

// ===== CRC32 via zlib (Qt links zlib internally) =====

quint32 MrtArchive::crc32(const QByteArray &data)
{
    return ::crc32(0L,
        reinterpret_cast<const Bytef *>(data.constData()),
        static_cast<uInt>(data.size()));
}

quint16 MrtArchive::dosTime()
{
    QDateTime now = QDateTime::currentDateTime();
    return static_cast<quint16>((now.time().hour() << 11) |
                                 (now.time().minute() << 5) |
                                 (now.time().second() >> 1));
}

quint16 MrtArchive::dosDate()
{
    QDateTime now = QDateTime::currentDateTime();
    return static_cast<quint16>(((now.date().year() - 1980) << 9) |
                                 (now.date().month() << 5) |
                                 now.date().day());
}

// ===== READ =====

QList<MrtArchiveEntry> MrtArchive::read(const QString &filePath)
{
    QList<MrtArchiveEntry> entries;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "[MRT] READ FAILED: cannot open" << filePath;
        return entries;
    }

    QByteArray fullData = file.readAll();
    file.close();
    qDebug() << "[MRT] read:" << filePath << "size:" << fullData.size();

    if (fullData.size() < 22) {
        qDebug() << "[MRT] file too small (< 22 bytes), not a ZIP";
        return entries;
    }

    int eocdPos = -1;
    for (int i = fullData.size() - 22; i >= 0; i--) {
        if (fullData[i]   == 0x50 && fullData[i+1] == 0x4b &&
            fullData[i+2] == 0x05 && fullData[i+3] == 0x06) {
            eocdPos = i;
            break;
        }
    }
    if (eocdPos < 0) {
        qDebug() << "[MRT] EOCD not found, not a valid ZIP";
        return entries;
    }

    quint32 centralDirOffset;
    memcpy(&centralDirOffset, fullData.constData() + eocdPos + 16, 4);
    qDebug() << "[MRT] EOCD at" << eocdPos << "centralDirOffset:" << centralDirOffset;

    // Walk central directory
    int pos = static_cast<int>(centralDirOffset);
    while (pos + 46 <= fullData.size()) {
        quint32 sig;
        memcpy(&sig, fullData.constData() + pos, 4);
        if (sig != CENTRAL_HEADER_SIG)
            break;

        quint16 nameLen, extraLen, commentLen;
        memcpy(&nameLen,   fullData.constData() + pos + 28, 2);
        memcpy(&extraLen,  fullData.constData() + pos + 30, 2);
        memcpy(&commentLen, fullData.constData() + pos + 32, 2);

        quint32 localOffset;
        memcpy(&localOffset, fullData.constData() + pos + 42, 4);

        QString name = QString::fromUtf8(
            fullData.constData() + pos + 46, nameLen);

        // Read local header to get data size
        if (localOffset + 30 > static_cast<quint32>(fullData.size()))
            break;

        quint16 lNameLen, lExtraLen;
        quint32 compSize;
        memcpy(&lNameLen,  fullData.constData() + localOffset + 26, 2);
        memcpy(&lExtraLen, fullData.constData() + localOffset + 28, 2);
        memcpy(&compSize,  fullData.constData() + localOffset + 18, 4);

        int dataOffset = static_cast<int>(localOffset + 30 + lNameLen + lExtraLen);
        if (dataOffset + static_cast<int>(compSize) > fullData.size())
            break;

        QByteArray data = fullData.mid(dataOffset, static_cast<int>(compSize));
        entries.append({name, data});
        qDebug() << "[MRT]   entry:" << name << "size:" << compSize;

        pos += 46 + nameLen + extraLen + commentLen;
    }

    qDebug() << "[MRT] read OK:" << entries.size() << "entries";
    return entries;
}

QByteArray MrtArchive::readSingle(const QString &filePath, const QString &entryName)
{
    QList<MrtArchiveEntry> entries = read(filePath);
    for (const auto &e : entries) {
        if (e.name == entryName)
            return e.data;
    }
    return {};
}

// ===== WRITE =====

bool MrtArchive::write(const QString &filePath, const QList<MrtArchiveEntry> &entries)
{
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qDebug() << "[MRT] WRITE FAILED: cannot open" << filePath;
        return false;
    }

    QByteArray centralDir;
    quint32 offset = 0;
    quint16 dosDate_ = dosDate();
    quint16 dosTime_ = dosTime();

    QByteArray fileData;

    qDebug() << "[MRT] write:" << filePath << "entries:" << entries.size();

    for (const auto &entry : entries) {
        QByteArray nameBytes = entry.name.toUtf8();
        quint16 nameLen = static_cast<quint16>(nameBytes.size());
        quint32 size = static_cast<quint32>(entry.data.size());
        quint32 crc = crc32(entry.data);
        qDebug() << "[MRT] entry:" << entry.name << "size:" << size << "crc:" << crc;

        // ===== Local file header (30 + name) =====
        // ZIP local header layout:
        //   0-3: signature  |  4-5: version  |  6-7: flags  |  8-9: comp method
        //  10-11: time  |  12-13: date  |  14-17: crc  |  18-21: csize  |  22-25: usize
        //  26-27: nameLen  |  28-29: extraLen  |  30+: name
        QByteArray localHeader(30 + nameLen, '\0');
        quint32 sig = LOCAL_HEADER_SIG;
        memcpy(localHeader.data() + 0,  &sig, 4);
        quint16 version = 20;
        memcpy(localHeader.data() + 4,  &version, 2);
        // offset 6-7 flags = 0 (\0-init = STORED)
        // offset 8-9 comp method = 0 (\0-init = STORED)
        memcpy(localHeader.data() + 10, &dosTime_, 2);
        memcpy(localHeader.data() + 12, &dosDate_, 2);
        memcpy(localHeader.data() + 14, &crc, 4);
        memcpy(localHeader.data() + 18, &size, 4);
        memcpy(localHeader.data() + 22, &size, 4);
        memcpy(localHeader.data() + 26, &nameLen, 2);
        // offset 28-29 extraLen = 0 (\0-init)
        memcpy(localHeader.data() + 30, nameBytes.constData(), nameLen);

        fileData.append(localHeader);
        fileData.append(entry.data);

        // ===== Central directory entry (46 + name) =====
        // ZIP central dir layout:
        //   0-3: signature  |  4-5: ver made  |  6-7: ver need  |  8-9: flags
        //  10-11: comp method  |  12-13: time  |  14-15: date  |  16-19: crc
        //  20-23: csize  |  24-27: usize  |  28-29: nameLen  |  30-31: extraLen
        //  32-33: commentLen  |  34-35: disk  |  36-37: intAttr  |  38-41: extAttr
        //  42-45: localOffset  |  46+: name
        QByteArray centralEntry(46 + nameLen, '\0');
        sig = CENTRAL_HEADER_SIG;
        memcpy(centralEntry.data() + 0,  &sig, 4);
        version = 20;
        quint16 versionMadeBy = (3 << 8) | 20; // Unix host, ZIP 2.0
        memcpy(centralEntry.data() + 4,  &versionMadeBy, 2);
        memcpy(centralEntry.data() + 6,  &version, 2);
        // offset 8-9 flags = 0
        // offset 10-11 comp method = 0 (\0-init = STORED)
        memcpy(centralEntry.data() + 12, &dosTime_, 2);  // was bug: wrote to offset 10
        memcpy(centralEntry.data() + 14, &dosDate_, 2);  // was bug: wrote to offset 12
        memcpy(centralEntry.data() + 16, &crc, 4);
        memcpy(centralEntry.data() + 20, &size, 4);
        memcpy(centralEntry.data() + 24, &size, 4);
        memcpy(centralEntry.data() + 28, &nameLen, 2);
        memcpy(centralEntry.data() + 42, &offset, 4);
        memcpy(centralEntry.data() + 46, nameBytes.constData(), nameLen);

        centralDir.append(centralEntry);
        offset += static_cast<quint32>(localHeader.size() + entry.data.size());
    }

    // ===== End of central directory (22) =====
    QByteArray eocd(22, '\0');
    quint32 eocdSig = EOCD_SIG;
    memcpy(eocd.data() + 0,  &eocdSig, 4);
    quint16 numEntries = static_cast<quint16>(entries.size());
    memcpy(eocd.data() + 8,  &numEntries, 2);
    memcpy(eocd.data() + 10, &numEntries, 2);
    quint32 cdSize = static_cast<quint32>(centralDir.size());
    quint32 cdOffset = offset;
    memcpy(eocd.data() + 12, &cdSize, 4);
    memcpy(eocd.data() + 16, &cdOffset, 4);

    // Write everything
    file.write(fileData);
    file.write(centralDir);
    file.write(eocd);
    file.close();

    qDebug() << "[MRT] wrote" << fileData.size() + centralDir.size() + eocd.size() << "bytes, entries:" << entries.size() << "cdOffset:" << cdOffset;

    return true;
}
