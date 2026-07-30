# XMPP Specifications & Feature Implementation Checklist

A comprehensive list of XMPP RFC standards, XMPP Extension Protocols (XEPs), and modern client specifications for **Qubber**, organized by functional domain and aligned with XSF Compliance Suites (XEP-0443 / XEP-0487).

---

## 1. Core Standards, Transport & Authentication

- [x] **RFC 6120: XMPP Core** — XML Streams, TLS, SASL authentication (SCRAM-SHA-1/256, PLAIN, ANONYMOUS)
- [x] **RFC 6121: XMPP Instant Messaging & Presence** — Roster management, presence subscription (`subscribe`/`subscribed`), basic chat messaging
- [ ] **RFC 7590: Use of Transport Layer Security (TLS) in XMPP** — TLS best practices & mandatory encryption enforcement
- [ ] **RFC 7622: XMPP Address Format** — Modern JID parsing, stringprep/precis rules, validation
- [x] **Secure Keyring Credential Storage** — OS Keyring integration (SecretService / GNOME Keyring / KWallet) for secure credential storage
- [ ] **XEP-0138: Stream Compression** — zlib stream compression to minimize mobile network payload
- [ ] **XEP-0156: Discovering Alternative Connection Methods** — WebSocket (`wss://`) and BOSH (`https://`) fallback transport discovery
- [ ] **XEP-0368: SRV Records for XMPP over TLS** — Direct TLS connection on port 5223 skipping STARTTLS roundtrip
- [ ] **XEP-0388: Extensible SASL (SASL2)** — Fast authentication negotiation & inline stream features
- [ ] **XEP-0386: Bind 2** — Streamlined resource binding combined with authentication

---

## 2. Service Discovery, Capabilities & Entity Management

- [x] **XEP-0030: Service Discovery** — Querying server and client capabilities, features, and identities (`disco#info`, `disco#items`)
- [x] **XEP-0115: Entity Capabilities** — Broadcasting identity hashes (`c` element) in presence to eliminate redundant disco queries
- [x] **XEP-0092: Software Version** — Standard software name, version, and OS querying
- [x] **XEP-0232: Software Information** — Detailed client version and platform information exchange

---

## 3. Presence, Profiles, Avatars & Status

- [x] **XEP-0012: Last Activity** — Querying and displaying contact last-seen timestamps (`jabber:iq:last`)
- [x] **XEP-0054: vCard-temp** — Legacy profile vCard retrieval and avatar image downloads
- [x] **XEP-0084: User Avatar** — Modern PubSub/PEP avatar metadata publication & binary image retrieval
- [x] **XEP-0153: vCard-Based Avatars** — Avatar SHA-1 hash inclusion in presence stanzas for legacy clients
- [x] **XEP-0392: Consistent Color Generation** — Algorithmic hashing of JIDs for consistent user avatar color schemes
- [ ] **XEP-0163: Personal Eventing Protocol (PEP)** — User-centric PubSub model for micro-blogging, avatars, and status events
- [ ] **XEP-0292: vCard4 Over Personal Eventing Protocol** — Next-generation XML/vCard4 profile metadata over PEP
- [ ] **XEP-0107: User Mood** — Publishing and displaying real-time user emotional state
- [ ] **XEP-0108: User Activity** — Publishing current real-world activity status
- [ ] **XEP-0482: User Tune / Media Status** — Broadcasting currently playing audio track & media

---

## 4. Messaging & Rich Chat Experience

- [x] **XEP-0085: Chat State Notifications** — Real-time typing status (`composing`, `paused`, `active`, `inactive`, `gone`)
- [x] **XEP-0184: Message Delivery Receipts** — Delivery acknowledgments and multi-stage status indicators (sending, sent, delivered)
- [ ] **XEP-0280: Message Carbons** — Real-time bidirectional message synchronization across multiple online client instances
- [ ] **XEP-0308: Last Message Correction** — Editing and updating previously transmitted messages
- [ ] **XEP-0313: Message Archive Management (MAM)** — Querying server-side message history for offline catching and pagination
- [ ] **XEP-0333: Chat Markers** — Granular chat markers (`received`, `displayed`, `acknowledged`) for read-receipt UX
- [ ] **XEP-0359: Unique and Stable Stanza IDs** — Canonical, server-assigned `origin-id` and `stanza-id` tracking
- [ ] **XEP-0393: Message Formatting** — Plain-text markup, markdown-style rich formatting (bold, italic, code blocks, quotes)
- [ ] **XEP-0424: Message Retraction** — Protocol for server-side and client-side message deletion
- [ ] **XEP-0428: Fallback Indication** — Marking plaintext fallback bodies for non-supporting fallback clients
- [ ] **XEP-0444: Message Reactions** — Sending and rendering emoji reactions on specific messages
- [ ] **XEP-0461: Message Replies** — Quoted reply threading referencing prior message IDs
- [ ] **XEP-0071: XHTML-IM** — Legacy rich-text HTML message formatting support

---

## 5. Group Chats, Channels & Multi-User Collaboration

- [ ] **XEP-0045: Multi-User Chat (MUC)** — Full group chat rooms, participant rosters, roles, affiliations, and topic management
- [ ] **XEP-0249: Direct MUC Invitations** — One-to-one direct invitations to group channels with password/reason payloads
- [ ] **XEP-0410: MUC Self-Ping** — Automated background connection heartbeats to detect silent MUC drops
- [ ] **XEP-0425: Moderated MUC / Moderation** — Retracting or hiding abusive messages in group channels by room moderators
- [ ] **XEP-0437: MUC Light** — Lightweight multi-user chat protocol optimized for mobile clients and simpler sync
- [ ] **XEP-0434: Trust Messages for Group Encryption** — Trust state notification across multi-user chat participants

---

## 6. File Transfer, Media Sharing & Attachments

- [x] **XEP-0363: HTTP File Upload** — Secure HTTP slot request and direct PUT upload for inline file/image sharing
- [ ] **XEP-0234: Jingle File Transfer** — Peer-to-peer file transfer negotiations over Jingle transport
- [ ] **XEP-0065: SOCKS5 Bytestreams (S5B)** — High-speed direct TCP or mediated proxy binary data streams
- [ ] **XEP-0047: In-Band Bytestreams (IBB)** — Reliable chunked XML binary fallback for strict NAT/firewall environments
- [ ] **XEP-0264: Jingle Content Thumbnails** — Inline low-resolution image/video thumbnails in file transfer offers
- [ ] **XEP-0385: Stateless Inline Media Sharing (SIMS)** — Embedding media links with pre-calculated metadata & encryption keys
- [ ] **XEP-0446: File Metadata** — Comprehensive metadata schemas (MIME type, size, dimensions, checksums, duration)
- [ ] **XEP-0447: Stateless File Sharing (SFS)** — Modern abstracted file transfer transport selection framework

---

## 7. Security, Privacy & End-to-End Encryption (E2EE)

- [x] **XEP-0384: OMEMO Encryption** — Modern multi-device E2EE protocol leveraging Signal Double Ratchet algorithm (v0.3 & v0.8+)
- [ ] **XEP-0373: OpenPGP for XMPP** — Modern OpenPGP XML bindings for end-to-end payload signing & encryption
- [ ] **XEP-0420: Stanza Header Encryption (SDE)** — Encrypting stanza headers (to/from/timestamps) inside E2EE envelopes to prevent metadata leakage
- [x] **XEP-0454: OMEMO Media Sharing** — AES-GCM media encryption for HTTP File Upload attachments
- [ ] **XEP-0191: Blocking Command** — User-managed blacklisting and blocking of abusive JIDs
- [ ] **XEP-0377: Spam Reporting** — Standardized abuse reporting to server administrators

---

## 8. Voice, Video & Real-Time Communications (Jingle / RTC)

- [ ] **XEP-0166: Jingle** — Core session management protocol for peer-to-peer audio, video, and data calls
- [ ] **XEP-0167: Jingle RTP Sessions** — Audio and video media stream negotiation over WebRTC / RTP
- [ ] **XEP-0176: Jingle ICE-UDP Transport Method** — Interactive Connectivity Establishment (ICE) for NAT traversal
- [ ] **XEP-0278: Jingle Relay Nodes** — TURN/Relay server candidate discovery for peer-to-peer fallback
- [ ] **XEP-0320: Use of DTLS-SRTP in Jingle Sessions** — End-to-end media encryption handshake for WebRTC calls

---

## 9. Mobile Optimizations, Backgrounding & Push Notifications

- [x] **XEP-0030: Service Discovery** — Discovering server capabilities, features, and identity
- [x] **Linux Desktop Notifications & Sound Alerts** — Native FreeDesktop desktop toasts (contact name & text) and audio alerts (`message.opus`, `typing.opus`)
- [ ] **XEP-0198: Stream Management** — Stream session resumption, quick reconnect, and stanza ACK tracking across network switches
- [ ] **XEP-0352: Client State Indication (CSI)** — Informing server of foreground/background state to pause non-essential stanzas
- [ ] **XEP-0357: Push Notifications** — Delegating notification delivery to mobile gateways (FCM/APNs) when app is killed/suspended
- [ ] **XEP-0199: XMPP Ping** — Server and peer keepalive pinging to monitor underlying TCP connection integrity

---

## 10. Account Administration & Data Portability

- [ ] **XEP-0077: In-Band Registration (IBR)** — Creating new XMPP accounts and changing passwords directly from the client
- [ ] **XEP-0227: Portable Import/Export Format** — Exporting and importing user rosters, history, and settings in XML standard format
- [ ] **XEP-0157: Contact Addresses for XMPP Services** — Server support and administrative contact discovery

---

## 11. XSF Compliance Suites Alignment

- [ ] **XEP-0443: XMPP Compliance Suites 2021/2022/2023** — Advanced Mobile Client & Core Client compliance target
- [ ] **XEP-0487: XMPP Compliance Suites 2024+** — Modern standards baseline verification
