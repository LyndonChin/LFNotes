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

`Certificate` 就是证书，握手时双方（peer & local）各自交换证书，具体的证书类型都继承自 `Certificate`，例如 `X509Certificate`。

*from wiki*
> In cryptography, X.509 is an important standard for a public key infrastructure (PKI) to manage digital certificates[1] and public-key encryption[2] and a key part of the Transport Layer Security protocol used to secure web and email communication. An ITU-T standard, X.509 specifies formats for public key certificates, certificate revocation lists, attribute certificates, and a certification path validation algorithm.

---

除了以上数据之外，`Handshake` 还有两个静态 `get` 方法，可以通过参数创建一个 `Handshake` 实例。

```java
public static Handshake get(SSLSession session);
public static Handshake get(TlsVersion tlsVersion, CipherSuite cipherSuite, 
    List<Certificate> peerCertificates, List<Certificate> localCertificates)
```

其中 `SSLSession` 由 JDK 提供 - `javax.net.ssl.SSLSession`，从字面意思上看就是一个 SSL 会话，暂不深究。它与 `Handshake` 的对应关系如下：

```java
String cipherSuiteString = session.getCipherSuite();
String tlsVersionString = session.getProtocol();
Certificate[] peerCertificates = session.getPeerCertificates();
Certificate[] localCertificates = session.getLocalCertificates();
```

总之，`get` 方法会创建一个 `Handshake` 实例。


参考文章
---

* http://insights.thoughtworkers.org/cipher-behind-https/

