#include <ruby.h>
#include <sys/vfs.h>

static VALUE get_disk_usage(VALUE self, VALUE mount_point)
{
   char* mount_point_str = RSTRING(mount_point)->ptr;

   VALUE out_hash = rb_hash_new();
   rb_hash_aset(out_hash, rb_str_new2("free"), Qnil);
   rb_hash_aset(out_hash, rb_str_new2("total"), Qnil);

   struct statfs result;

   if(statfs(mount_point_str, &result) == 0)
   {
      rb_hash_aset(out_hash, rb_str_new2("free"), LL2NUM((long long)result.f_bfree * (long long)result.f_bsize));
      rb_hash_aset(out_hash, rb_str_new2("total"), LL2NUM((long long)result.f_blocks * (long long)result.f_bsize));
   }

   return out_hash;
}

void Init_disk_usage()
{
   VALUE mDataProviders = rb_const_get(rb_cObject, rb_intern("DataProviders"));
   VALUE cDiskUsage = rb_const_get(mDataProviders, rb_intern("DiskUsage"));
   
   rb_define_method(cDiskUsage, "get_disk_usage", get_disk_usage, 1);
}
