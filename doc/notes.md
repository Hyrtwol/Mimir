# Odin notes

## VSCode setup

* <https://code.visualstudio.com/docs/editor/variables-reference>

## Snippets

```odin
memory_buffer : []u8 = ---
ofs, len: i32 = ---
str1 := string(memory_buffer[ofs:ofs + len])
str2 := string(memory_buffer[ofs:][:len])
```

```odin
win32.MessageBoxW(nil, win32.utf8_to_wstring("Title should be " + TITLE), wtitle, win32.MB_OK)
os.read(os.stdin)
```

## Misc

```txt
C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\um
C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\um\WinUser.h
C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\um\mmeapi.h
```

## Links

* <https://stackoverflow.com/questions/21163188/most-simple-but-complete-cmake-example>
* <https://cezarypiatek.github.io/post/develop-vsextension-with-github-actions/>
* <https://www.codeproject.com/articles/251892/guide-to-image-composition-with-win32-msimg32-dll>
