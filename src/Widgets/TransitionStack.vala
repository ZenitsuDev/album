// Thanks to Alexander Mikhaylenko for this.
public class TransitionStack : Gtk.Widget {
    private class SharedElement {
        public Gtk.Widget? src;
        public Gtk.Widget? dst;

        public Gtk.Picture src_pic;
        public Gtk.Picture dst_pic;

        public bool running;
        public bool schedule_init;
    }

    private SharedElement[] shared;

    private Adw.TimedAnimation animation;
    private double progress;

    private Gtk.Widget visible_child;

    private Gtk.Widget? src;
    private Gtk.Widget? dst;

    public signal void animation_done ();

    public void add_child (Gtk.Widget widget) {
        widget.set_parent (this); // TODO make sure it's before the transition pics

        if (visible_child == null)
            visible_child = widget;
        else
            widget.set_child_visible (false);
    }

    public void add_shared_element (Gtk.Widget source, Gtk.Widget dest) {
        var element = new SharedElement ();

        element.src = source;
        element.dst = dest;

        element.src_pic = new Gtk.Picture () {
            can_shrink = false,
            overflow = Gtk.Overflow.HIDDEN,
            visible = false,
            can_target = false
        };

        element.dst_pic = new Gtk.Picture () {
            can_shrink = false,
            overflow = Gtk.Overflow.HIDDEN,
            visible = false,
            can_target = false
        };

        shared += element;
    }

    public void navigate (Gtk.Widget widget) {
        if (src != null)
            return;

        src = visible_child;
        dst = visible_child = widget;

        dst.set_child_visible (true);

        foreach (var element in shared) {
            element.src_pic.paintable = new Gtk.WidgetPaintable (element.src).get_current_image ();
            element.src_pic.show ();

            element.src.opacity = 0;

            element.src_pic.set_parent (this);
            element.dst_pic.set_parent (this);

            element.running = true;
            element.schedule_init = true;
        }

        set_progress (0);

        animation = new Adw.TimedAnimation (this, 0, 1, 300, new Adw.CallbackAnimationTarget ((value) => {
            set_progress (value);
        }));
        animation.done.connect (() => {
            animation = null;

            foreach (var element in shared) {
                element.src.opacity = 1;
                element.dst.opacity = 1;

                element.src_pic.unparent ();
                element.dst_pic.unparent ();
            }

            shared = {};

            src.set_child_visible (false);
            src = null;
            dst = null;
            animation_done ();
        });
        animation.play ();
    }

    private void set_progress (double progress) {
        this.progress = progress;

        queue_allocate ();
    }

    construct {
        overflow = Gtk.Overflow.HIDDEN;

        shared = {};
    }

    protected override void dispose () {
        var child = get_first_child ();

        while (child != null) {
            var c = child;
            child = child.get_next_sibling ();

            c.unparent ();
        }

        base.dispose ();
    }

    protected override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        minimum = 0;
        natural = 0;
        minimum_baseline = -1;
        natural_baseline = -1;

        for (var c = get_first_child (); c != null; c = c.get_next_sibling ()) {
            if (!c.should_layout ())
                continue;

            bool skip = false;
            foreach (var element in shared) {
                if (c == element.src_pic || c == element.dst_pic) {
                    skip = true;
                    break;
                }
            }

            if (skip)
                continue;

            int child_min = 0, child_nat = 0;
            int child_min_baseline = -1;
            int child_nat_baseline = -1;

            c.measure (orientation, for_size, out child_min, out child_nat,
                       out child_min_baseline, out child_nat_baseline);

            minimum = int.max (minimum, child_min);
            natural = int.max (natural, child_nat);

            if (child_min_baseline > -1)
                minimum_baseline = int.max (minimum_baseline, child_min_baseline);

            if (child_nat_baseline > -1)
                natural_baseline = int.max (natural_baseline, child_nat_baseline);
        }
    }

    private inline Graphene.Matrix get_allocated_transform (Gtk.Widget widget) {
        Graphene.Matrix ret, mat = {};

        widget.compute_transform (this, out ret);

        var context = widget.get_style_context ();
        var margin = context.get_margin ();
        var padding = context.get_padding ();
        var border = context.get_border ();

        mat.init_identity ();
        mat = mat.multiply (ret);
        mat.translate ({
            -margin.left - padding.left - border.left - widget.margin_start,
            -margin.top  - padding.top  - border.top - widget.margin_top,
            0
        });

        return mat;
    }

    protected override void size_allocate (int width, int height, int baseline) {
        for (var c = get_first_child (); c != null; c = c.get_next_sibling ()) {
            if (!c.should_layout ())
                continue;

            bool skip = false;
            foreach (var element in shared) {
                if (c == element.src_pic || c == element.dst_pic) {
                    skip = true;
                    break;
                }
            }

            if (skip)
                continue;

            c.allocate (width, height, baseline, null);
        }

        Graphene.Size origin = { 1, 1 };

        foreach (var element in shared) {
            if (!element.running)
                continue;

            int w_src = element.src.get_allocated_width ();
            int h_src = element.src.get_allocated_height ();
            // float aspect_src = (float) w_src / (float) h_src;
            var src_matrix = get_allocated_transform (element.src);

            int w_dst = element.dst.get_allocated_width ();
            int h_dst = element.dst.get_allocated_height ();
            // float aspect_dst = (float) w_dst / (float) h_dst;
            var dst_matrix = get_allocated_transform (element.dst);

            var transform_src = new Gsk.Transform ();
            var transform_dst = new Gsk.Transform ();

            transform_src = transform_src.matrix (src_matrix.interpolate (dst_matrix, progress));
            transform_dst = transform_dst.matrix (dst_matrix.interpolate (src_matrix, 1 - progress));

            var size_src = origin.interpolate ({ (float) w_dst / w_src, (float) h_dst / h_src }, progress);
            var size_dst = origin.interpolate ({ (float) w_src / w_dst, (float) h_src / h_dst }, 1 - progress);

            transform_src = transform_src.scale (size_src.width, size_src.height);
            transform_dst = transform_dst.scale (size_dst.width, size_dst.height);

            element.src_pic.allocate (w_src, h_src, baseline, transform_src);
            element.dst_pic.allocate (w_dst, h_dst, baseline, transform_dst);
        }
    }

    protected override void snapshot (Gtk.Snapshot snapshot) {
        if (animation == null) {
            snapshot_child (visible_child, snapshot);
            return;
        }
        snapshot.push_cross_fade (progress);
        snapshot_child (src, snapshot);
        snapshot.pop ();
        snapshot_child (dst, snapshot);
        snapshot.pop ();

        foreach (var element in shared) {
            if (!element.running)
                continue;

            if (element.schedule_init) {
                element.dst_pic.paintable = new Gtk.WidgetPaintable (element.dst).get_current_image ();
                element.dst_pic.show ();
                element.dst.opacity = 0;

                snapshot_child (element.src_pic, snapshot);

                element.schedule_init = false;
            } else {
                snapshot.push_cross_fade (progress);
                snapshot_child (element.src_pic, snapshot);
                snapshot.pop ();
                snapshot_child (element.dst_pic, snapshot);
                snapshot.pop ();
            }
        }
    }
}
