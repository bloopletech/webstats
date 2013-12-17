#include <ruby.h>
#include <sys/statvfs.h>

static VALUE get_disk_usage(VALUE self, VALUE mount_point)
{
   struct statvfs result;
   char* mount_point_str = RSTRING_PTR(mount_point);

   VALUE out_hash = rb_hash_new();
   rb_hash_aset(out_hash, rb_str_new2("free"), Qnil);
   rb_hash_aset(out_hash, rb_str_new2("total"), Qnil);

   //struct statvfs result;  <-- ISO C90 forbids mixed declarations and code

   if(statvfs(mount_point_str, &result) == 0)
   {
      rb_hash_aset(out_hash, rb_str_new2("free"), LL2NUM((long long)result.f_bavail * (long long)result.f_frsize));
      rb_hash_aset(out_hash, rb_str_new2("total"), LL2NUM((long long)result.f_blocks * (long long)result.f_frsize));
   }

   return out_hash;
}

void Init_disk_usage()
{
   VALUE mDataProviders = rb_const_get(rb_cObject, rb_intern("DataProviders"));
   VALUE cDiskUsage = rb_const_get(mDataProviders, rb_intern("DiskUsage"));
   
   rb_define_method(cDiskUsage, "get_disk_usage", get_disk_usage, 1);
}
