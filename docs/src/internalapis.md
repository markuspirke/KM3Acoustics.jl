## Commonly used
```@autodocs
Modules = [KM3Acoustics]
Filter   = t -> contains(string(t), "Lazy")
```

## More Internal
```@autodocs
Modules = [KM3Acoustics]
Filter   = t -> !(contains(string(t), "Lazy"))
```
