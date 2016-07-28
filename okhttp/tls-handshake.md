我们从 `okhttp3.Handshake` 开始，彻底搞懂什么是 Handshake。

Handshake 是双方在正式传送数据之前的一次“握手”，双方要在协商一致的前提下才能继续沟通，否则拜拜。

```java
public final class Handshake {
  private final TlsVersion tlsVersion;
  private final CipherSuite cipherSuite;
  private final List<Certificate> peerCertificates;
  private final List<Certificate> localCertificates;
  // ...
}
```

Handshake 的成员变量表明了它所需要的数据。

> 注意它们都有 `final` 修饰。

首先是本次 handshake 所支持的 TLS 版本 - `TlsVersion tlsVersion`。

## TlsVersion

*okhttp3.TlsVersion*
```java
public enum TlsVersion {
  TLS_1_2("TLSv1.2"), // 2008.
  TLS_1_1("TLSv1.1"), // 2006.
  TLS_1_0("TLSv1"),   // 1999.
  SSL_3_0("SSLv3"),   // 1996.
  ;
}
```

SSL协议是Netcape公司于上世纪90年代中期提出的协议，自身发展到3.0版本。1999年该协议由ITEL接管，进行了标准化，改名为TLS。

## CipherSuite

`CipherSuite` 可以简单理解成是**密钥算法套件**。

*from wiki*
> A cipher suite is a named combination of authentication, encryption, message authentication code (MAC) and key exchange algorithms used to negotiate the security settings for a network connection using the Transport Layer Security (TLS) / Secure Sockets Layer (SSL) network protocol. 

`okhttp3.CipherSuite` 的定义非常简单，只有一个名字。

```java
public final class CipherSuite {
  final String javaName;
}
```

okhttp 把它所支持的 `CipherSuite` 存放在 `INSTANCES` 中，然后定义了很多 `CipherSuite` 类型的静态成员变量：

```java
private static final ConcurrentMap<String, CipherSuite> INSTANCES = new ConcurrentHashMap<>();

public static final CipherSuite TLS_RSA_WITH_NULL_MD5 = of("SSL_RSA_WITH_NULL_MD5", 0x0001);
public static final CipherSuite TLS_RSA_WITH_NULL_SHA = of("SSL_RSA_WITH_NULL_SHA", 0x0002);
public static final CipherSuite TLS_RSA_EXPORT_WITH_RC4_40_MD5 = of("SSL_RSA_EXPORT_WITH_RC4_40_MD5", 0x0003);
public static final CipherSuite TLS_RSA_WITH_RC4_128_MD5 = of("SSL_RSA_WITH_RC4_128_MD5", 0x0004);
public static final CipherSuite TLS_RSA_WITH_RC4_128_SHA = of("SSL_RSA_WITH_RC4_128_SHA", 0x0005);
// ....
```




参考文章
---

* http://insights.thoughtworkers.org/cipher-behind-https/

