Calculate 1+1 and print out

With this script we calculate the sum of 1 and 1 and print it out
to the command line. We print it out as integer and as 2-digit
float.



```r
# evaluate nothing at all:
```



calculate 1+1


```r
result = 1+1
```

print the result out as integer


```r
print(formatC(result, format='d'))
```

print the result out as integer


```r
print(formatC(result, format='f', width=4, digits=2))
```

