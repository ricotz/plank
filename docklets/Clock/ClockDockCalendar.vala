using Plank;

namespace Docky
{
    public class ClockDockCalendar : Gtk.Window {
        public ClockDockCalendar () {
            this.title = "Plank Clock Calendar";
            this.border_width = 5;
            this.set_default_size (300, 50);
            Gtk.Window.set_default_icon_name("calendar");
            this.set_position (Gtk.WindowPosition.MOUSE);

            Gtk.Calendar calendar = new Gtk.Calendar ();
            this.add (calendar);
        }
    }
}
