<?xml version="1.0"?>
<api version="1.0">
	<namespace name="bamf">
		<enum name="BamfWindowType">
			<member name="BAMF_WINDOW_NORMAL" value="0"/>
			<member name="BAMF_WINDOW_DESKTOP" value="1"/>
			<member name="BAMF_WINDOW_DOCK" value="2"/>
			<member name="BAMF_WINDOW_DIALOG" value="3"/>
			<member name="BAMF_WINDOW_TOOLBAR" value="4"/>
			<member name="BAMF_WINDOW_MENU" value="5"/>
			<member name="BAMF_WINDOW_UTILITY" value="6"/>
			<member name="BAMF_WINDOW_SPLASHSCREEN" value="7"/>
		</enum>
		<object name="BamfApplication" parent="BamfView" type-name="BamfApplication" get-type="bamf_application_get_type">
			<method name="get_application_type" symbol="bamf_application_get_application_type">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="application" type="BamfApplication*"/>
				</parameters>
			</method>
			<method name="get_desktop_file" symbol="bamf_application_get_desktop_file">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="application" type="BamfApplication*"/>
				</parameters>
			</method>
			<method name="get_show_menu_stubs" symbol="bamf_application_get_show_menu_stubs">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="application" type="BamfApplication*"/>
				</parameters>
			</method>
			<method name="get_windows" symbol="bamf_application_get_windows">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="application" type="BamfApplication*"/>
				</parameters>
			</method>
			<method name="get_xids" symbol="bamf_application_get_xids">
				<return-type type="GArray*"/>
				<parameters>
					<parameter name="application" type="BamfApplication*"/>
				</parameters>
			</method>
			<signal name="window-added" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfApplication*"/>
					<parameter name="p0" type="BamfView*"/>
				</parameters>
			</signal>
			<signal name="window-removed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfApplication*"/>
					<parameter name="p0" type="BamfView*"/>
				</parameters>
			</signal>
		</object>
		<object name="BamfControl" parent="GObject" type-name="BamfControl" get-type="bamf_control_get_type">
			<method name="get_default" symbol="bamf_control_get_default">
				<return-type type="BamfControl*"/>
			</method>
			<method name="insert_desktop_file" symbol="bamf_control_insert_desktop_file">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="BamfControl*"/>
					<parameter name="desktop_file" type="gchar*"/>
				</parameters>
			</method>
			<method name="register_application_for_pid" symbol="bamf_control_register_application_for_pid">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="BamfControl*"/>
					<parameter name="application" type="gchar*"/>
					<parameter name="pid" type="gint32"/>
				</parameters>
			</method>
			<method name="register_tab_provider" symbol="bamf_control_register_tab_provider">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="BamfControl*"/>
					<parameter name="path" type="char*"/>
				</parameters>
			</method>
			<method name="set_approver_behavior" symbol="bamf_control_set_approver_behavior">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="BamfControl*"/>
					<parameter name="behavior" type="gint32"/>
				</parameters>
			</method>
		</object>
		<object name="BamfIndicator" parent="BamfView" type-name="BamfIndicator" get-type="bamf_indicator_get_type">
			<method name="get_dbus_menu_path" symbol="bamf_indicator_get_dbus_menu_path">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="BamfIndicator*"/>
				</parameters>
			</method>
			<method name="get_remote_address" symbol="bamf_indicator_get_remote_address">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="BamfIndicator*"/>
				</parameters>
			</method>
			<method name="get_remote_path" symbol="bamf_indicator_get_remote_path">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="BamfIndicator*"/>
				</parameters>
			</method>
		</object>
		<object name="BamfMatcher" parent="GObject" type-name="BamfMatcher" get-type="bamf_matcher_get_type">
			<method name="application_is_running" symbol="bamf_matcher_application_is_running">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
					<parameter name="application" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_active_application" symbol="bamf_matcher_get_active_application">
				<return-type type="BamfApplication*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
				</parameters>
			</method>
			<method name="get_active_window" symbol="bamf_matcher_get_active_window">
				<return-type type="BamfWindow*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
				</parameters>
			</method>
			<method name="get_application_for_window" symbol="bamf_matcher_get_application_for_window">
				<return-type type="BamfApplication*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
					<parameter name="window" type="BamfWindow*"/>
				</parameters>
			</method>
			<method name="get_application_for_xid" symbol="bamf_matcher_get_application_for_xid">
				<return-type type="BamfApplication*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
					<parameter name="xid" type="guint32"/>
				</parameters>
			</method>
			<method name="get_applications" symbol="bamf_matcher_get_applications">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
				</parameters>
			</method>
			<method name="get_default" symbol="bamf_matcher_get_default">
				<return-type type="BamfMatcher*"/>
			</method>
			<method name="get_running_applications" symbol="bamf_matcher_get_running_applications">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
				</parameters>
			</method>
			<method name="get_tabs" symbol="bamf_matcher_get_tabs">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
				</parameters>
			</method>
			<method name="get_windows" symbol="bamf_matcher_get_windows">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
				</parameters>
			</method>
			<method name="get_xids_for_application" symbol="bamf_matcher_get_xids_for_application">
				<return-type type="GArray*"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
					<parameter name="application" type="gchar*"/>
				</parameters>
			</method>
			<method name="register_favorites" symbol="bamf_matcher_register_favorites">
				<return-type type="void"/>
				<parameters>
					<parameter name="matcher" type="BamfMatcher*"/>
					<parameter name="favorites" type="gchar**"/>
				</parameters>
			</method>
			<signal name="active-application-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfMatcher*"/>
					<parameter name="p0" type="GObject*"/>
					<parameter name="p1" type="GObject*"/>
				</parameters>
			</signal>
			<signal name="active-window-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfMatcher*"/>
					<parameter name="p0" type="GObject*"/>
					<parameter name="p1" type="GObject*"/>
				</parameters>
			</signal>
			<signal name="view-closed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfMatcher*"/>
					<parameter name="p0" type="GObject*"/>
				</parameters>
			</signal>
			<signal name="view-opened" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfMatcher*"/>
					<parameter name="p0" type="GObject*"/>
				</parameters>
			</signal>
		</object>
		<object name="BamfTabSource" parent="GObject" type-name="BamfTabSource" get-type="bamf_tab_source_get_type">
			<method name="get_tab_ids" symbol="bamf_tab_source_get_tab_ids">
				<return-type type="char**"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
				</parameters>
			</method>
			<method name="get_tab_preview" symbol="bamf_tab_source_get_tab_preview">
				<return-type type="GArray*"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</method>
			<method name="get_tab_uri" symbol="bamf_tab_source_get_tab_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</method>
			<method name="get_tab_xid" symbol="bamf_tab_source_get_tab_xid">
				<return-type type="guint32"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</method>
			<method name="show_tab" symbol="bamf_tab_source_show_tab">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
					<parameter name="error" type="GError*"/>
				</parameters>
			</method>
			<property name="id" type="char*" readable="1" writable="1" construct="1" construct-only="0"/>
			<signal name="tab-closed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfTabSource*"/>
					<parameter name="p0" type="char*"/>
				</parameters>
			</signal>
			<signal name="tab-opened" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfTabSource*"/>
					<parameter name="p0" type="char*"/>
				</parameters>
			</signal>
			<signal name="tab-uri-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="BamfTabSource*"/>
					<parameter name="p0" type="char*"/>
					<parameter name="p1" type="char*"/>
					<parameter name="p2" type="char*"/>
				</parameters>
			</signal>
			<vfunc name="show_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</vfunc>
			<vfunc name="tab_ids">
				<return-type type="char**"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
				</parameters>
			</vfunc>
			<vfunc name="tab_preview">
				<return-type type="GArray*"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</vfunc>
			<vfunc name="tab_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</vfunc>
			<vfunc name="tab_xid">
				<return-type type="guint32"/>
				<parameters>
					<parameter name="source" type="BamfTabSource*"/>
					<parameter name="tab_id" type="char*"/>
				</parameters>
			</vfunc>
		</object>
		<object name="BamfView" parent="GObject" type-name="BamfView" get-type="bamf_view_get_type">
			<method name="get_children" symbol="bamf_view_get_children">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="get_icon" symbol="bamf_view_get_icon">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="bamf_view_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="get_view_type" symbol="bamf_view_get_view_type">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="is_active" symbol="bamf_view_is_active">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="is_closed" symbol="bamf_view_is_closed">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="is_running" symbol="bamf_view_is_running">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="is_urgent" symbol="bamf_view_is_urgent">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<method name="is_user_visible" symbol="bamf_view_user_visible">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</method>
			<property name="active" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="path" type="char*" readable="1" writable="1" construct="1" construct-only="0"/>
			<property name="running" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="urgent" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="user-visible" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<signal name="active-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
					<parameter name="active" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="child-added" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
					<parameter name="child" type="BamfView*"/>
				</parameters>
			</signal>
			<signal name="child-removed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
					<parameter name="child" type="BamfView*"/>
				</parameters>
			</signal>
			<signal name="closed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</signal>
			<signal name="running-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
					<parameter name="running" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="urgent-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
					<parameter name="urgent" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="user-visible-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
					<parameter name="user_visible" type="gboolean"/>
				</parameters>
			</signal>
			<vfunc name="get_children">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_icon">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
			<vfunc name="is_active">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
			<vfunc name="is_running">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
			<vfunc name="is_urgent">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
			<vfunc name="view_type">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="view" type="BamfView*"/>
				</parameters>
			</vfunc>
		</object>
		<object name="BamfWindow" parent="BamfView" type-name="BamfWindow" get-type="bamf_window_get_type">
			<method name="get_transient" symbol="bamf_window_get_transient">
				<return-type type="BamfWindow*"/>
				<parameters>
					<parameter name="self" type="BamfWindow*"/>
				</parameters>
			</method>
			<method name="get_window_type" symbol="bamf_window_get_window_type">
				<return-type type="BamfWindowType"/>
				<parameters>
					<parameter name="self" type="BamfWindow*"/>
				</parameters>
			</method>
			<method name="get_xid" symbol="bamf_window_get_xid">
				<return-type type="guint32"/>
				<parameters>
					<parameter name="self" type="BamfWindow*"/>
				</parameters>
			</method>
			<method name="last_active" symbol="bamf_window_last_active">
				<return-type type="time_t"/>
				<parameters>
					<parameter name="self" type="BamfWindow*"/>
				</parameters>
			</method>
		</object>
	</namespace>
</api>
