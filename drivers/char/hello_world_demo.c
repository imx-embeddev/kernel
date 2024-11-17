#include <linux/kernel.h>
#include <linux/init.h>     /* module_init module_exit */
#include <linux/module.h>   /* MODULE_LICENSE */


// 模块入口函数
int __init hello_world_demo_init(void)
{
    printk("hello_world_demo module is running!\n");
	return 0;
}

// 模块出口函数
void __exit hello_world_demo_exit(void)
{
	printk("hello_world_demo will exit\n");
}

// 将__init定义的函数指定为驱动的入口函数
module_init(hello_world_demo_init);


// 将__exit定义的函数指定为驱动的出口函数
module_exit(hello_world_demo_exit);

/* 模块信息(通过 modinfo hello_world_demo 查看) */
MODULE_LICENSE("GPL");               /* 源码的许可证协议 */
MODULE_AUTHOR("sumu");               /* 字符串常量内容为模块作者说明 */
MODULE_DESCRIPTION("Description");   /* 字符串常量内容为模块功能说明 */
MODULE_ALIAS("module's other name"); /* 字符串常量内容为模块别名 */
