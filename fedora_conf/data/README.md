To add test files, EXPORT **FOXML-1.1** format in the **archive** context.
Note that as of August 2015, Fedora 3.x export is broken, so adding test file by export does not
actually work. Hopefully, one day we'll get a working export in Fedora.

Both load order and inclusion is determined by the file "load_order".

The difference between **archive** and **migrate** contexts is:

```diff
- <foxml:contentLocation TYPE="INTERNAL_ID" REF="druid:xt996nh9743+descMetadata+descMetadata.0"/>
+ <foxml:binaryContent> 
+   ...
+ </foxml:binaryContent> 
```

Example export from fedora URL:
```bash
for x in xt996nh9743 ts750tk2598 ; do
  wget -O $x.xml --user=fedoraAdmin --password=fedoraAdmin "localhost:8983/fedora/objects/druid%3A$x/export?context=archive"
done
```
