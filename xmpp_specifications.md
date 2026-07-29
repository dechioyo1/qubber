# XMPP Specifications & Feature Implementation Checklist

A comprehensive list of XMPP RFC standards and XMPP Extension Protocols (XEPs) for **Qubber**, organized by functional domain.

---

## 1. Core Standards & Authentication

- [x] **RFC 6120: XMPP Core** — XML Streams, TLS, SASL authentication (SCRAM-SHA-1, Plain, etc.)
- [x] **RFC 6121: XMPP Instant Messaging & Presence** — Roster management, presence subscription (`subscribe`/`subscribed`), and basic chat messaging
- [x] **Secure Keyring Credential Storage** — Desktop OS Keyring integration (SecretService / GNOME Keyring / KWallet) for credentials security

---

## 2. Presence, Profile & Avatars

- [x] **XEP-0012: Last Activity** — Querying and displaying contact last seen status (`jabber:iq:last`)
- [x] **XEP-0054: vCard-temp** — Profile vCard retrieval and avatar image downloads
- [x] **XEP-0084: User Avatar** — User avatar discovery
- [x] **XEP-0153: vCard-Based Avatars** — Avatar hash presence notifications
- [x] **XEP-0392: Consistent Color Generation** — Algorithmic avatar color generation for contacts
- [ ] **XEP-0292: vCard4 Over Personal Eventing Protocol** — Modern vCard4 profiles

---

## 3. Messaging & Chat Experience

- [x] **XEP-0085: Chat State Notifications** — Real-time typing indicators (`composing`, `paused`, `active`)
- [x] **XEP-0184: Message Delivery Receipts** — Delivery receipt acknowledgments and status indicators (sending, sent, read)
- [ ] **XEP-0280: Message Carbons** — Real-time message synchronization across multiple logged-in devices
- [ ] **XEP-0308: Last Message Correction** — Editing previously sent messages
- [ ] **XEP-0313: Message Archive Management (MAM)** — Server-side message history fetching & syncing
- [ ] **XEP-0333: Chat Markers** — Fine-grained read/displayed/received markers
- [ ] **XEP-0359: Unique and Stable Stanza IDs** — Permanent stanza identifiers across sessions
- [ ] **XEP-0393: Message Formatting** — Plain-text markup and styling in chat messages
- [ ] **XEP-0424: Message Retraction** — Retracting/deleting messages server-side
- [ ] **XEP-0444: Message Reactions** — Emoji reactions on messages

---

## 4. Group Chats & Multi-User Collaboration

- [ ] **XEP-0045: Multi-User Chat (MUC)** — Group chat rooms, occupant lists, roles & permissions
- [ ] **XEP-0249: Direct MUC Invitations** — Direct group chat invite stanzas
- [ ] **XEP-0437: MUC Light** — Simplified multi-user chat protocol

---

## 5. File Transfer & Media Sharing

- [x] **XEP-0363: HTTP File Upload** — Uploading images and files via HTTP slot request for inline sharing
- [ ] **XEP-0234: Jingle File Transfer** — Peer-to-peer file transfer over Jingle
- [ ] **XEP-0065: SOCKS5 Bytestreams** — Direct or mediated binary data transfer

---

## 6. Security & End-to-End Encryption (E2EE)

- [x] **XEP-0384: OMEMO Encryption** — Multi-end-to-multi-end encryption based on Signal protocol (Double Ratchet)
- [ ] **XEP-0373: OpenPGP for XMPP** — End-to-end encryption using OpenPGP keys

---

## 7. Connection Resilience & Mobile Optimizations

- [x] **XEP-0030: Service Discovery** — Discovering server capabilities, features, and identity
- [ ] **XEP-0198: Stream Management** — Stream resumption and stanza acknowledgments after network drop
- [ ] **XEP-0352: Client State Indication (CSI)** — Informing server when client is idle or in background
- [ ] **XEP-0357: Push Notifications** — Mobile push notifications via app server gateway
