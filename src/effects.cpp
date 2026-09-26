/*
 * Copyright (C) 2026 LingmoOS Team.
 *
 * Author:     devalexandre <alexandre@dev2learn.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "effects.h"

#include <QDBusInterface>
#include <QDir>
#include <QDBusReply>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QStandardPaths>
#include <QVariantMap>

#include <optional>

Effects::Effects(QObject *parent)
    : QObject(parent)
    , m_kwinrc(new QSettings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/kwinrc",
                             QSettings::IniFormat, this))
{
}

bool Effects::defaultEnabled(const QString &id) const
{
    // Built-in effects, scripted effects and Lingmo's own scripts all carry
    // KPlugin.EnabledByDefault in their metadata
    const QStringList candidates = {
        QStringLiteral("kwin-x11/builtin-effects/%1.json").arg(id),
        QStringLiteral("kwin-x11/effects/%1/metadata.json").arg(id),
        QStringLiteral("kwin/effects/%1/metadata.json").arg(id),
        QStringLiteral("kwin/scripts/%1/metadata.json").arg(id),
        QStringLiteral("kwin-x11/scripts/%1/metadata.json").arg(id),
    };
    const auto enabledByDefault = [](const QString &path, const QString &id, bool checkId) -> std::optional<bool> {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            return std::nullopt;
        const QJsonObject plugin = QJsonDocument::fromJson(file.readAll()).object().value("KPlugin").toObject();
        if (checkId && plugin.value("Id").toString() != id)
            return std::nullopt;
        return plugin.value("EnabledByDefault").toBool(false);
    };

    for (const QString &candidate : candidates) {
        const QString path = QStandardPaths::locate(QStandardPaths::GenericDataLocation, candidate);
        if (!path.isEmpty()) {
            if (const auto value = enabledByDefault(path, id, false))
                return *value;
        }
    }

    // Packages whose directory isn't named after their id (Lingmo's ling_popups is lingmo_popups)
    for (const QString &base : {QStringLiteral("kwin/effects"), QStringLiteral("kwin-x11/effects")}) {
        const QStringList roots = QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, base, QStandardPaths::LocateDirectory);
        for (const QString &root : roots) {
            const QStringList packages = QDir(root).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString &package : packages) {
                if (const auto value = enabledByDefault(root + '/' + package + "/metadata.json", id, true))
                    return *value;
            }
        }
    }
    return false;
}

bool Effects::isEnabled(const QString &id) const
{
    // The user's kwinrc, then the system ones (Lingmo's defaults live in
    // /etc/xdg/kwinrc), then the effect's own default
    const QStringList files = QStandardPaths::locateAll(QStandardPaths::GenericConfigLocation, QStringLiteral("kwinrc"));
    for (const QString &path : files) {
        QSettings kwinrc(path, QSettings::IniFormat);
        const QVariant value = kwinrc.value("Plugins/" + id + "Enabled");
        if (value.isValid())
            return value.toBool();
    }
    return defaultEnabled(id);
}

void Effects::setEnabledMany(const QVariantMap &states)
{
    m_kwinrc->beginGroup("Plugins");
    for (auto it = states.cbegin(); it != states.cend(); ++it)
        m_kwinrc->setValue(it.key() + "Enabled", it.value().toBool());
    m_kwinrc->endGroup();
    m_kwinrc->sync();
    reloadKWin();
    ++m_revision;
    emit changed();
}

void Effects::setEnabled(const QString &id, bool enabled)
{
    setEnabledMany({{id, enabled}});
}

bool Effects::isSupported(const QString &id) const
{
    QDBusInterface effects("org.kde.KWin", "/Effects", "org.kde.kwin.Effects");
    if (!effects.isValid())
        return true;
    const QDBusReply<bool> reply = effects.call("isEffectSupported", id);
    return !reply.isValid() || reply.value();
}

QString Effects::switcherLayout() const
{
    m_kwinrc->beginGroup("TabBox");
    const QString layout = m_kwinrc->value("LayoutName", "ling_thumbnail").toString();
    m_kwinrc->endGroup();
    return layout;
}

void Effects::setSwitcherLayout(const QString &layout)
{
    if (layout == switcherLayout())
        return;
    m_kwinrc->beginGroup("TabBox");
    m_kwinrc->setValue("LayoutName", layout);
    m_kwinrc->endGroup();
    m_kwinrc->sync();
    reloadKWin();
    emit switcherLayoutChanged();
}

int Effects::revision() const
{
    return m_revision;
}

void Effects::reloadKWin()
{
    QDBusInterface("org.kde.KWin", "/KWin", "org.kde.KWin").call("reconfigure");
}
