# hangulromanize

A LuaLaTeX package for romanization of Korean as per official system proclaimed by Korean Government.

국어 로마자 표기법에 따라 한글을 로마자로 변환해주는 루아텍 패키지

## Usage

```
\Romanize*{벚꽃}[벋꼳]
```
국어 로마자 표기법 제2장의 표기법을 따른다.
별표 명령은 첫 글자를 대문자로 만든다.
인자 뒤에 발음을 옵션으로 줄 수 있으며 분철이 필요하면 사용자가 넣어준다.

```
\RomanizeA*{벚꽃}
```
국어 로마자 표기법 제3장 제8항의 전자법에 따른다.
별표 명령은 첫 글자를 대문자로 만든다.
분철은 자동으로 이루어진다.

```
\HangulizeA{eobs-eoss-seubnida}
```
국어 로마자 표기법 제3장 제8항의 전자법을 역적용하여 로마자를 한글로 변환한다.

## License

Public Domain.
