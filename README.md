# less-autocompile package

Auto compile LESS file on save.

---

Add the parameters on the first line of the LESS file.

```
out (string):  path of CSS file to create
compress (bool): compress CSS file (default: false)
main (string): path to your main LESS file to be compiled
sourceMap (bool): define if your project will have source map (default: true)
```

```
// out: ../styles.css
```

```
// out: ../styles.css, compress: true
```

```
// main: init.less
```

```
// sourceMap: ../styles.css, sourceMap: true
```

![](http://uppix.net/2pENDo.gif)
