#ifndef _SUSFS_H
#define _SUSFS_H

#include <linux/list.h>
#include <linux/hash.h>
#include <linux/types.h>
#include <linux/fs.h>
#include <linux/mount.h>

// 定义哈希表大小（根据实际需求调整）
#define SUSFS_HASH_BITS 10

// 定义inode状态标志位（确保与内核其他标志不冲突）
#define INODE_STATE_SUS_PATH  (1 << 30)  // 使用高位避免冲突
#define INODE_STATE_SUS_MOUNT (1 << 29)
#define INODE_STATE_SUS_KSTAT (1 << 28)
#define INODE_STATE_OPEN_REDIRECT (1 << 27)

// 最大路径长度定义
#define SUSFS_MAX_LEN_PATHNAME 256
#define __NEW_UTS_LEN 64

// try_umount 模式定义
#define TRY_UMOUNT_DEFAULT 0
#define TRY_UMOUNT_DETACH 1

// Magic mount 工作目录
#define MAGIC_MOUNT_WORKDIR "/debug_ramdisk/mount/"

// 命令行配置大小
#define SUSFS_FAKE_CMDLINE_OR_BOOTCONFIG_SIZE 4096

// SUSFS 版本
#define SUSFS_VERSION "v3.1.9-8e43b2d6@susfs-test"

// 挂载标志位定义
#ifndef MNT_DETACH
#define MNT_DETACH 2
#endif

// 路径定义
#define DATA_ADB_UMOUNT_FOR_ZYGOTE_SYSTEM_PROCESS "/data/adb/sus_umount_for_zygote_system_process"
#define DATA_ADB_NO_AUTO_ADD_SUS_BIND_MOUNT "/data/adb/sus_no_auto_add_sus_bind_mount"
#define DATA_ADB_NO_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT "/data/adb/sus_no_auto_add_sus_ksu_default_mount"
#define DATA_ADB_NO_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT "/data/adb/sus_no_auto_add_try_umount_for_bind_mount"

// 命令定义
#define CMD_SUSFS_ADD_SUS_PATH 0x1
#define CMD_SUSFS_ADD_SUS_PATH_LOOP 0x2
#define CMD_SUSFS_SET_ANDROID_DATA_ROOT_PATH 0x3
#define CMD_SUSFS_SET_SDCARD_ROOT_PATH 0x4
#define CMD_SUSFS_ADD_SUS_MOUNT 0x5
#define CMD_SUSFS_HIDE_SUS_MNTS_FOR_ALL_PROCS 0x6
#define CMD_SUSFS_UMOUNT_FOR_ZYGOTE_ISO_SERVICE 0x7
#define CMD_SUSFS_ADD_SUS_KSTAT 0x8
#define CMD_SUSFS_UPDATE_SUS_KSTAT 0x9
#define CMD_SUSFS_ADD_SUS_KSTAT_STATICALLY 0x10
#define CMD_SUSFS_ADD_TRY_UMOUNT 0x11
#define CMD_SUSFS_RUN_UMOUNT_FOR_CURRENT_MNT_NS 0x12
#define CMD_SUSFS_SET_UNAME 0x13
#define CMD_SUSFS_ENABLE_LOG 0x14
#define CMD_SUSFS_SET_CMDLINE_OR_BOOTCONFIG 0x15
#define CMD_SUSFS_ADD_OPEN_REDIRECT 0x16
#define CMD_SUSFS_SUS_SU 0x17
#define CMD_SUSFS_SHOW_VERSION 0x18
#define CMD_SUSFS_SHOW_ENABLED_FEATURES 0x19
#define CMD_SUSFS_SHOW_VARIANT 0x1A
#define CMD_SUSFS_IS_SUS_SU_READY 0x1B
#define CMD_SUSFS_SHOW_SUS_SU_WORKING_MODE 0x1C
#define CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING 0x1D
#define CMD_SUSFS_GET_SUSFS_FEATURE_STATUS 0x1E

// SUS SU 模式定义
#define SUS_SU_WITH_HOOKS 1
#define SUS_SU_DISABLED 0
#define SUS_SU_WITH_OVERLAY 2

// SUSFS 变体
#define SUSFS_VARIANT "susfs"

// 结构体定义
struct st_susfs_sus_path {
	unsigned long                    target_ino;
	char                             target_pathname[SUSFS_MAX_LEN_PATHNAME];
};

struct st_susfs_sus_path_hlist {
    	unsigned long                    target_ino;
    	char                             target_pathname[SUSFS_MAX_LEN_PATHNAME];
    	struct hlist_node                node;
};

struct st_susfs_sus_mount {
	char                    target_pathname[SUSFS_MAX_LEN_PATHNAME];
	unsigned long           target_dev;
};

struct st_susfs_sus_mount_list {
   	struct list_head                        list;
   	struct st_susfs_sus_mount               info;
};

struct st_susfs_sus_kstat {
	int                     is_statically;
	unsigned long           target_ino; // 绑定挂载或覆盖后的ino
	char                    target_pathname[SUSFS_MAX_LEN_PATHNAME];
	unsigned long           spoofed_ino;
	unsigned long           spoofed_dev;
	unsigned int            spoofed_nlink;
	long long               spoofed_size;
	long                    spoofed_atime_tv_sec;
	long                    spoofed_mtime_tv_sec;
	long                    spoofed_ctime_tv_sec;
	long                    spoofed_atime_tv_nsec;
	long                    spoofed_mtime_tv_nsec;
	long                    spoofed_ctime_tv_nsec;
	unsigned long           spoofed_blksize;
	unsigned long long      spoofed_blocks;
};

struct st_susfs_sus_kstat_hlist {
  	unsigned long                           target_ino;
  	struct st_susfs_sus_kstat               info;
  	struct hlist_node                       node;
};

struct st_susfs_try_umount {
	char                    target_pathname[SUSFS_MAX_LEN_PATHNAME];
	int                     mnt_mode;
};

struct st_susfs_try_umount_list {
  	struct list_head                        list;
  	struct st_susfs_try_umount              info;
};

struct st_susfs_uname {
	char        release[__NEW_UTS_LEN+1];
	char        version[__NEW_UTS_LEN+1];
};

struct st_susfs_open_redirect {
	unsigned long                    target_ino;
	char                             target_pathname[SUSFS_MAX_LEN_PATHNAME];
	char                             redirected_pathname[SUSFS_MAX_LEN_PATHNAME];
};

struct st_susfs_open_redirect_hlist {
  	unsigned long                    target_ino;
  	char                             target_pathname[SUSFS_MAX_LEN_PATHNAME];
  	char                             redirected_pathname[SUSFS_MAX_LEN_PATHNAME];
  	struct hlist_node                node;
};

struct st_sus_su {
	int         mode;
};

// SUSFS功能状态结构体
struct susfs_feature_status {
 	// 根据实际功能定义字段
 	unsigned int sus_path:1;
 	unsigned int sus_mount:1;
 	unsigned int sus_kstat:1;
 	unsigned int try_umount:1;
 	unsigned int spoof_uname:1;
 	unsigned int open_redirect:1;
 	unsigned int sus_su:1;
 	unsigned int enable_log:1;
 	unsigned int hide_symbols:1;
 	unsigned int spoof_cmdline:1;
 	unsigned int magic_mount:1;
 	// 其他功能标志位
};

#endif /* _SUSFS_H */