#!/vendor/bin/sh

# Add adbd to nnapi vendor cgroup. (b/222226268)
echo `pidof adbd` > /proc/vendor_sched/groups/nnapi/set_task_group
