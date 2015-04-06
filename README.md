# less-compiler package
This is a fork from lohek less-autocompile all credits for him to the great idea well im only doing some modifications for get a better performance and some functionality that i needed.

Auto compile LESS file on save.
---

Add the parameters on the first line of the LESS file.

```
out (string):  path of CSS file to create
compress (bool): compress CSS file
main (string): path to your main LESS file to be compiled
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

Ps: if u have more than one main file u can do this

```
// main: one.less|two.less|another.less
```

This is only working for main option

[![Share the love!](https://www.paypalobjects.com/pt_BR/BR/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=AMS87WQKEVEHG)
