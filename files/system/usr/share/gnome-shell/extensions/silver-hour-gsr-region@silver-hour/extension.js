// silver-hour GSR region.
//
// GNOME's own org.gnome.Shell.Screenshot D-Bus interface is restricted to an
// allowlist of senders, so gpu-screen-recorder's helper scripts cannot call it.
// This extension lives *inside* the shell and exposes the same interactive
// area selection over its own object path, so the helpers can ask for a region
// and then let GSR do the (GPU-accelerated) capture.
//
// The object is exported on the shell's own connection; clients call it via
// org.gnome.Shell at /io/github/silverhour/GsrRegion. Selection returns
// unscaled desktop coordinates in gpu-screen-recorder's "WxH+X+Y" space.
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Screenshot from 'resource:///org/gnome/shell/ui/screenshot.js';

const IFACE = `
<node>
  <interface name="io.github.silverhour.GsrRegion">
    <method name="SelectArea">
      <arg type="i" direction="out" name="x"/>
      <arg type="i" direction="out" name="y"/>
      <arg type="i" direction="out" name="width"/>
      <arg type="i" direction="out" name="height"/>
    </method>
  </interface>
</node>`;

const OBJECT_PATH = '/io/github/silverhour/GsrRegion';

export default class GsrRegionExtension extends Extension {
    enable() {
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, OBJECT_PATH);
    }

    disable() {
        if (this._dbus) {
            this._dbus.flush();
            this._dbus.unexport();
            this._dbus = null;
        }
    }

    SelectAreaAsync(_params, invocation) {
        const selectArea = new Screenshot.SelectArea();
        selectArea.selectAsync().then(rect => {
            if (!rect) {
                invocation.return_error_literal(
                    Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED, 'Selection cancelled');
                return;
            }
            const scale = St.ThemeContext.get_for_stage(global.stage).scale_factor;
            invocation.return_value(GLib.Variant.new('(iiii)', [
                Math.round(rect.x / scale),
                Math.round(rect.y / scale),
                Math.round(rect.width / scale),
                Math.round(rect.height / scale),
            ]));
        }).catch(() => {
            invocation.return_error_literal(
                Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED, 'Selection cancelled');
        });
    }
}
