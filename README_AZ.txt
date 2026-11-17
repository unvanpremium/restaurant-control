RESTAURANT CONTROL — ONLAYN PWA STARTER
========================================

Bu paket sayt + telefona quraşdırıla bilən PWA tətbiqinin ilkin onlayn versiyasıdır.
Supabase layihəniz və Vercel yerləşdirməniz qurulmadan canlı hesablar işləməyəcək.

1) SUPABASE LAYİHƏSİ
- https://supabase.com saytında hesab yaradın və New project seçin.
- Project URL və anon/publishable key dəyərlərini Project Settings > API bölməsindən götürün.
- SQL Editor bölməsində supabase_setup.sql faylının bütün məzmununu icra edin.
- Authentication > Providers bölməsində Email aktiv qalsın.
- Authentication > Settings bölməsində öz qeydiyyat səhifəniz yoxdursa, istifadəçiləri Dashboard > Authentication > Users > Add user ilə administrator özü yaratsın.
- İstifadəçilər yaradıldıqdan sonra SQL Editor-də README-nin sonundakı nümunəyə uyğun profiles.role dəyərlərini admin / owner / manager edin.
  İlk istifadəçiyə admin rolu verin. Rəhbər hesabları manager olaraq qala bilər.
- E-poçt təsdiqi aktivdirsə, yaradılan istifadəçinin e-poçtunu təsdiqləyin və ya Supabase ayarlarınıza uyğun təsdiq prosesini tamamlayın.

2) CONFIG.JS
- config.js faylını açın.
- SUPABASE_URL yerinə Project URL yazın.
- SUPABASE_ANON_KEY yerinə anon/publishable key yazın.
- Service role key-i heç vaxt brauzer koduna yazmayın və paylaşmayın.

3) VERCEL-DƏ YAYIM
- Paketi ZIP-dən çıxarın.
- Qovluğu GitHub repository-yə yükləyin.
- https://vercel.com saytında GitHub ilə daxil olun və həmin repository-ni Import edin.
- Framework preset: Other; Build command boş; Output directory: . (root) seçin.
- Deploy edin. Vercel sizə pulsuz *.vercel.app ünvanı verəcək.
- Saytı HTTPS ünvanı ilə açın. Telefonda brauzerin menyusundan “Add to Home Screen” / “Ana ekrana əlavə et” seçin.

4) ROLLAR
- admin: bütün qeydləri idarə edə bilər.
- owner: bütün qeydləri görə və redaktə edə bilər.
- manager: problemləri görə, əlavə edə və yeniləyə bilər.
- Bu ilkin sxemdə bütün daxil olmuş istifadəçilər eyni restoranın problem siyahısını görür.

VACİB TƏHLÜKƏSİZLİK QEYDLƏRİ
- Bu, ilk inteqrasiya paketidir; real istifadəçilərə verməzdən əvvəl Supabase RLS siyasətlərini və girişləri öz mühitinizdə test edin.
- Foto bucket-i public qurulub: şəkillərin linkini əldə edən şəxs onu görə bilər. Məxfi şəkillər üçün private bucket və signed URL qurulmalıdır.
- E-poçt/şifrə hesablarını yalnız etibarlı şəxslər üçün yaradın.
- Pulsuz hostinq və verilənlər bazası limitləri və şərtləri dəyişə bilər.
- Proqramın internetdə işləməsi üçün Supabase və Vercel hesablarını istifadəçi özü açmalı, layihəni deploy etməlidir. Mən sizin hesabınıza daxil ola və sizin yerinizə hesab yarada bilmirəm.

DƏSTƏK
Əvvəlcə Supabase layihəsini yaradın. Sonra Project URL və anon/publishable key-i config.js-ə yerləşdirin. Bu açarları söhbətə göndərməyin; deploy zamanı özünüz əlavə edin.
