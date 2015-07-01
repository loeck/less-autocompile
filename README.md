# less-autocompile package

Auto compile LESS file on save.

---

Add the parameters on the first line of the LESS file.

```
out (string):  path of CSS file to create
sourcemap (bool): create sourcemap file
compress (bool): compress CSS file
main (string): path to your main LESS file to be compiled
autoprefixer(string): value is passed as browsers to the autoprefixer-plugin, separate multiple entires with a ; character
cleancss: value is passed as compatibility to the cleancss-plugin - not compatible with source-maps
```

## Example
less/styles.less
```scss
// out: ../css/styles.css, sourcemap: true, compress: true

@import "my/components/select.less";
```

less/my/components/select.less
```scss
// main: ../../styles.less

.select {
  height: 100px;
  width: 100px;
}
```
