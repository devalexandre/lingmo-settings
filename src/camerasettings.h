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

#ifndef CAMERASETTINGS_H
#define CAMERASETTINGS_H

#include <QObject>
#include <QVariantList>

// Auto framing options, applied by lingmo-camera (com.lingmo.Camera on the session bus)
class CameraSettings : public QObject
{
    Q_OBJECT
    // The service is running
    Q_PROPERTY(bool running READ running NOTIFY changed)
    // The virtual camera exists (v4l2loopback is loaded)
    Q_PROPERTY(bool available READ available NOTIFY changed)
    // An app is using the camera now
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(bool framing READ framing WRITE setFraming NOTIFY changed)
    // "wide", "medium" or "close"
    Q_PROPERTY(QString zoom READ zoom WRITE setZoom NOTIFY changed)
    // Device of the real camera, "" for automatic
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY changed)
    // [{ device, name }]
    Q_PROPERTY(QVariantList cameras READ cameras NOTIFY changed)

public:
    explicit CameraSettings(QObject *parent = nullptr);

    bool running() const { return m_running; }
    bool available() const { return m_available; }
    bool active() const { return m_active; }
    bool framing() const { return m_framing; }
    QString zoom() const { return m_zoom; }
    QString source() const { return m_source; }
    QVariantList cameras() const { return m_cameras; }

    void setFraming(bool on);
    void setZoom(const QString &zoom);
    void setSource(const QString &device);

    // Starts lingmo-camera if it isn't running
    Q_INVOKABLE void start();

signals:
    void changed();

private slots:
    void reload();

private:
    void set(const QString &name, const QVariant &value);

    bool m_running = false;
    bool m_available = false;
    bool m_active = false;
    bool m_framing = true;
    QString m_zoom = "medium";
    QString m_source;
    QVariantList m_cameras;
};

#endif // CAMERASETTINGS_H
