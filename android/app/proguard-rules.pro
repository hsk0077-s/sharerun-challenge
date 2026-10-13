# 릴리스 빌드의 코드 최적화(R8)가 아래 라이브러리를 지우거나 이름을 바꾸지 못하게 한다.
# 디버그에서는 최적화를 하지 않아 되던 것이 릴리스에서만 실패하는 문제를 막는다.

# 네이버 로그인(flutter_naver_login이 쓰는 네이버 SDK). 이 규칙이 없으면 릴리스에서
# "errorCode:no_catagorized_error"로 로그인 창이 열리기 전에 실패한다.
-keep public class com.navercorp.nid.** { *; }
-keep public class com.nhn.android.naverlogin.** { *; }
-dontwarn com.navercorp.nid.**
-dontwarn com.nhn.android.naverlogin.**

# 위 SDK가 쓰는 일반 속성.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
