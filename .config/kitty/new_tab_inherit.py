from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    src_tab = boss.active_tab
    active_bg = getattr(src_tab, 'active_bg', None) if src_tab is not None else None
    inactive_bg = getattr(src_tab, 'inactive_bg', None) if src_tab is not None else None

    boss.launch('--type=tab', '--cwd=current')

    new_tab = boss.active_tab
    if new_tab is None or new_tab is src_tab:
        return
    if active_bg is not None:
        new_tab.active_bg = active_bg
    if inactive_bg is not None:
        new_tab.inactive_bg = inactive_bg
    if active_bg is not None or inactive_bg is not None:
        tm = new_tab.tab_manager_ref() if hasattr(new_tab, 'tab_manager_ref') else None
        if tm is not None:
            tm.mark_tab_bar_dirty()
