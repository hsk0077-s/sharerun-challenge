# 릴리스 빌드의 코드 최적화(R8)가 아래 라이브러리를 지우거나 이름을 바꾸지 못하게 한다.
# 디버그에서는 최적화를 하지 않아 되던 것이 릴리스에서만 실패하는 문제를 막는다.
# AGP 8 이후 R8 full mode가 기본이라, 리플렉션으로 읽는 제네릭 시그니처가 지워진다.

# 네이버 로그인(flutter_naver_login이 쓰는 네이버 SDK 5.10.0).
# 클래스만 남기면 인터페이스인 Retrofit 서비스(NidOAuthLoginService)는 빠진다.
# 그 서비스의 suspend 함수 시그니처는
# Continuation<? super Response<NidOAuthResponse>> 이다. R8이 이를 raw Class로
# 바꾸면 토큰 요청의 Factory.create()에서
# ClassCastException: Class cannot be cast to ParameterizedType 이 난다.
# (인증 창은 열리고, 그다음 requestAccessToken에서 죽는 증상.)
-keep public class com.navercorp.nid.** { *; }
-keep public interface com.navercorp.nid.** { *; }
-keep public enum com.navercorp.nid.** { *; }
-keep public class com.nhn.android.naverlogin.** { *; }
-keep public interface com.nhn.android.naverlogin.** { *; }
-dontwarn com.navercorp.nid.**
-dontwarn com.nhn.android.naverlogin.**

# Retrofit 2.9 (네이버 SDK가 고정). 2.10 이전이라 consumer rules에 R8 full mode
# 대응이 없다. square/retrofit 의 retrofit2.pro 와 네아로 샘플 규칙을 따른다.
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations, AnnotationDefault

-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>

-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface * extends <1>

# 반환 타입의 제네릭이 지워지지 않게 응답 모델을 남긴다.
-if interface * { @retrofit2.http.* public *** *(...); }
-keep,allowoptimization,allowshrinking,allowobfuscation class <3>

# full mode는 keep되지 않은 타입의 Signature를 raw Class로 접는다.
# suspend 함수는 Continuation, Call<T> / Response<T> 가 그 대상이다.
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Gson이 SerializedName과 TypeToken으로 토큰 JSON을 읽는다.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-dontwarn retrofit2.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*
-dontwarn okhttp3.**
