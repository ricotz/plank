using Plank;

namespace Docky
{
    public class ClockDockCalendar : Gtk.Window {
        public ClockDockCalendar () {
            this.title = "Plank Clock Calendar";
            this.border_width = 5;
            this.set_default_size (300, 50);
            this.set_position (Gtk.WindowPosition.MOUSE);
            this.set_skip_taskbar_hint (true);
            Gtk.Window.set_default_icon_name("calendar");

            Gtk.Calendar calendar = new Gtk.Calendar ();
            this.add (calendar);
        }
    }
}
