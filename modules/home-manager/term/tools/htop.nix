{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    htop
  ];

  xdg.configFile."htop/htoprc".text = ''
    # Managed by nix-homelab
    htop_version=3.2.1
    config_reader_min_version=3
    fields=50 0 48 17 18 38 39 40 2 46 47 49 1
    hide_kernel_threads=1
    hide_userland_threads=1
    shadow_other_users=0
    show_thread_names=0
    show_program_path=1
    highlight_base_name=1
    highlight_deleted_exe=1
    highlight_megabytes=0
    highlight_threads=0
    highlight_changes=0
    highlight_changes_delay_secs=5
    find_comm_in_cmdline=1
    strip_exe_from_cmdline=1
    show_merged_command=0
    header_margin=1
    screen_tabs=1
    detailed_cpu_time=1
    cpu_count_from_one=0
    show_cpu_usage=1
    show_cpu_frequency=0
    show_cpu_temperature=0
    degree_fahrenheit=0
    update_process_names=0
    account_guest_in_cpu_meter=0
    color_scheme=6
    enable_mouse=1
    delay=15
    hide_function_bar=0
    header_layout=two_67_33
    column_meters_0=CPU AllCPUs
    column_meter_modes_0=2 1
    column_meters_1=Blank Clock Uptime System Tasks Swap Memory Blank LoadAverage CPU PressureStallCPUSome PressureStallIOSome PressureStallIOFull PressureStallMemorySome PressureStallMemoryFull DiskIO NetworkIO
    column_meter_modes_1=2 4 2 2 2 2 2 2 1 2 2 2 2 2 2 2 2
    tree_view=1
    sort_key=111
    tree_sort_key=46
    sort_direction=1
    tree_sort_direction=-1
    tree_view_always_by_pid=0
    all_branches_collapsed=0
    screen:Main=NLWP PID USER PRIORITY NICE M_VIRT M_RESIDENT M_SHARE STATE PERCENT_CPU PERCENT_MEM TIME Command
    .sort_key=IO_RATE
    .tree_sort_key=PERCENT_CPU
    .tree_view=1
    .tree_view_always_by_pid=0
    .sort_direction=1
    .tree_sort_direction=-1
    .all_branches_collapsed=0
    screen:I/O=PID USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE
    .sort_key=IO_RATE
    .tree_sort_key=PID
    .tree_view=0
    .tree_view_always_by_pid=0
    .sort_direction=-1
    .tree_sort_direction=1
    .all_branches_collapsed=0
  '';
}
