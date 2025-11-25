Identity Bedrock over Emercoin NVS and Skycoin‑Type Chains
Draft for review

Abstract
Public authentication in the classical PPT model has a provable floor: Rompel (STOC 1990) showed that one-way functions (OWF) are necessary and sufficient for EUF-CMA signatures. There is therefore no cryptographic primitive strictly “beneath” OWF that still enables publicly verifiable identity. Identity Bedrock isolates those minimal cryptographic primitives and mounts them on Emercoin’s hybrid (PoS + Bitcoin AuxPoW) consensus, chosen because its attack cost can be quantified and is sufficient for the institutional-capture threat model considered here.

We isolate that minimal structure and instantiate it using:

one‑way functions as the hardness floor (via Rompel),
Ed25519 signatures,
Emercoin’s blockchain and Name–Value Storage (NVS), and
WORM (World Object Mapper) JSON objects as identity records.
In the classical PPT model, public-key signatures (and hence publicly verifiable authentication) exist if one-way functions exist (Rompel, STOC 1990). We treat this as an unnegotiable floor: no strictly weaker primitive inside the usual model can undercut it.

**Identity Bedrock claim.** Within the standard PPT model, any public authentication system must assume:

1. One-way functions (⇔ EUF-CMA signatures) for the challenge–response predicate, and
2. Agreement on identifier→public-key bindings.

Identity Bedrock instantiates (1) with Ed25519 and (2) with Emercoin’s PoS + BTC AuxPoW directory. Removing the cryptographic assumption collapses authentication altogether; weakening the directory assumption is possible only if an alternative agreement mechanism can be shown to satisfy the same threat model at comparable cost. All additional trust, governance or interoperability must therefore live strictly above the individual key.

Any append-only directory with demonstrable finality can host the same construction; Emercoin is used here because its hybrid consensus and AuxPoW depth policy are publicly documented and costable.<sup>[1](https://emercoin.com/en/news/main-features-of-hybrid-mining/)</sup>

Legend (Acronyms / Abbreviations)

API – [Application Programming Interface](https://en.wikipedia.org/wiki/API)
BTC – [Bitcoin](https://en.wikipedia.org/wiki/Bitcoin) (native unit of the Bitcoin blockchain)
CA – [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority)
CMA – [Chosen-message attack](https://en.wikipedia.org/wiki/Digital_signature_forgery#Types) (appears in EUF-CMA)
EMC – [Emercoin](https://ru.wikipedia.org/wiki/Emercoin) (native unit / ticker)
EUF – [Existential Unforgeability](https://en.wikipedia.org/wiki/Digital_signature_forgery#Types) (appears in EUF-CMA)
ID – [Identifier](https://en.wikipedia.org/wiki/Identifier)
JSON – [JavaScript Object Notation](https://en.wikipedia.org/wiki/JSON)
KYC – [Know Your Customer](https://en.wikipedia.org/wiki/Know_your_customer)
MC19 – “Modern Cryptography 2019” lecture series cited
MCP – [Model Context Protocol](https://en.wikipedia.org/wiki/Model_Context_Protocol)
NESS – Privateness (native unit / ticker of the Privateness blockchain)
NVS – Name–Value Storage (Emercoin subsystem)
OIDC – [OpenID Connect](https://en.wikipedia.org/wiki/OpenID_Connect)
OS – [Operating System](https://en.wikipedia.org/wiki/Operating_system)
OWF – [One-Way Function](https://en.wikipedia.org/wiki/One-way_function)
PK – [Public Key](https://en.wikipedia.org/wiki/Public-key_cryptography)
PKI – [Public Key Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure)
PNG – [Portable Network Graphics](https://en.wikipedia.org/wiki/Portable_Network_Graphics) (image format for included figures)
PPT – [Probabilistic Polynomial-Time](https://en.wikipedia.org/wiki/Probabilistic_Turing_machine#Probabilistic_polynomial_time)
RC4OK – Fixed RC4 (Rivest Cipher 4) OK (Oleg Khovayko) integrated into Emercoin Core 0.8
RFC – [Request for Comments](https://en.wikipedia.org/wiki/Request_for_Comments) (IETF document series, e.g., RFC 8032)
RNG – [Random Number Generator](https://en.wikipedia.org/wiki/Random_number_generation)
SAML – [Security Assertion Markup Language](https://en.wikipedia.org/wiki/Security_Assertion_Markup_Language)
SK – [Secret Key](https://en.wikipedia.org/wiki/Symmetric-key_algorithm) (used implicitly alongside pk)
STOC – [ACM Symposium on Theory of Computing](https://en.wikipedia.org/wiki/ACM_Symposium_on_Theory_of_Computing)
UHEPRNG – Ultra-High Entropy Pseudo Random Number Generator
URN – [Uniform Resource Name](https://en.wikipedia.org/wiki/Uniform_Resource_Name)
UTXO – [Unspent Transaction Output](https://en.wikipedia.org/wiki/Unspent_transaction_output)
VM – [Virtual Machine](https://en.wikipedia.org/wiki/Virtual_machine)
WORM – World Object Mapper

Above this floor we add only:

a directory D binding identifiers id to public keys pk
(implemented as WORM JSON in Emer NVS), and
a challenge–response predicate Auth(id, c, σ) built from any EUF‑CMA secure signature scheme (instantiated here with Ed25519).
There is no Identity Provider, no CA root, no institutional key somewhere “under” the user; the only cryptographic root of trust is the individual sk plus Emer’s consensus assumptions. Any future Digital ID regime can only live strictly above this bedrock.

1. Motivation: resistance to Digital ID capture
The concrete adversary here is not “some hacker” but:

a global Digital ID stack (IdPs, SAML/OIDC providers, mobile OSes, X.509 CAs, cloud, KYC infrastructure),
with essentially unlimited conventional resources and political backing, and
full willingness to outlaw or deplatform alternatives.
What they do not control are:

the existence of one‑way functions, and
the consensus dynamics of chains they do not dominate economically.
The goal here is therefore not “integration” or “compliance”, but to deny such a regime any cryptographic foothold under the individual:

No institutional secret key appears in the definition of authentication.
No registry key, CA root, or IdP is assumed at the bedrock level.
Any attempt to recenter trust must move upwards (governance, distribution, coercion), because inside the usual PPT model there is nothing strictly below this construction to capture.
2. Hardness floor: one‑way functions and signatures
We work in the standard model of probabilistic polynomial‑time (PPT) adversaries.

2.1 One‑way functions (OWF)
A (family of) one‑way function(s) is an efficiently computable map
f : {0,1}*→ {0,1}* such that any PPT adversary A given f(x) has only negligible probability of finding any preimage x' with f(x') = f(x).

Rompel, “One‑Way Functions are Necessary and Sufficient for Secure Signatures”, STOC 1990
(full text: <https://www.cs.princeton.edu/courses/archive/spr08/cos598D/Rompel.pdf>)

proves:

OWF ⇒ there exists a EUF‑CMA signature scheme.
EUF‑CMA signature scheme ⇒ OWF exist.
So OWF are the minimal hardness assumption for signatures in the classical PPT model. There is no strictly weaker primitive under them that still supports public‑key authentication.

2.2 Digital signatures
We use an abstract signature scheme
Σ = (KeyGen, Sign, Verify) with the standard API:

KeyGen(1^λ) → (sk, pk)
Sign(sk, m) → σ
Verify(pk, m, σ) ∈ {0,1}
and EUF‑CMA security in the usual sense (see, e.g., Goldreich, Foundations of Cryptography, or Slamanig’s lecture: <https://danielslamanig.info/lectures/MC19_Lecture13.pdf>).

In practice we instantiate Σ as Ed25519 (RFC 8032): <https://datatracker.ietf.org/doc/html/rfc8032>.

3. Identity objects and directory
3.1 Identity
An identity is simply:

text
I := (id, pk)
id: arbitrary unique label (string, URN, hash of metadata, …).
pk: public verification key output by KeyGen.
3.2 Directory D and binding predicate
We assume a public directory:

text
D ⊆ ID × PK
with predicate:

text
Bind(id, pk) = 1  ⇔  (id, pk) ∈ D.
The bedrock layer is agnostic to how D is realized, as long as all honest verifiers agree on Bind. There is no assumption of X.509, CAs, or IdPs at this level.

4. Instantiation: WORM + Emercoin NVS
4.1 Emercoin NVS
Emercoin’s blockchain embeds Name–Value Storage (NVS): <https://emercoin.com/en/emercoin-blockchain>.

We treat:

the Emer ledger as an append‑only log, secured by Emer’s hybrid Proof‑of‑Stake + Bitcoin AuxPoW consensus (see e.g. <https://emercoin.com/en/news/main-features-of-hybrid-mining/>), and
NVS as a key–value table on that log.
Explorers show blocks flagged PoS and PoW; the PoW blocks are AuxPoW blocks referencing real Bitcoin work. Deep reorgs across those PoW “walls” are therefore BTC‑scale expensive, on top of Emer’s PoS stake requirements.

4.2 World Object Mapper (WORM)
The World Object Mapper (WORM) in the Ness / Privateness stack encodes structured “world objects” (users, nodes, services) as JSON values suitable for NVS.

Relevant repos:

Ness Service Node: <https://github.com/NESS-Network/NessNode>
Privateness Tools: <https://github.com/NESS-Network/PrivatenessTools>

![NESS MCP repositories overview](../mcp-ness.PNG)
*Figure: NESS MCP repositories for Emercoin, Privateness and Skywire MCP servers and apps.*

Commands like:

text
./key worm master01.key.json
./key worm http%3A%2F%2Fmy-node.net.key.json
take local JSON and output NVS values. Among other fields, such objects can contain:

an identifier id, and
a public key pk (Ed25519) intended as the verification key for that identity.
Instantiation of D.

D = set of all WORM objects committed in Emer NVS.
Bind(id, pk) = 1 iff the finalized WORM object for id in the Emer chain contains pk in the agreed field.
This is the only place Emer appears in the bedrock.

4.3 Finality, bootstrap, and fork handling
Bootstrapping trust in the WORM/NVS view requires more than “assuming Emer works”. We mandate:

1. Snapshot attestation.
   Operators publish signed snapshots (Merkle roots plus block heights) of the relevant NVS namespace. New verifiers compare at least two independent snapshots before accepting Bind(id, pk).
2. AuxPoW depth policy.
   A record is considered final only after it is buried behind both (a) the 120-block PoS confirmation window recommended by Emer core (roughly 12 hours) and (b) at least two AuxPoW “walls” (Emer blocks whose headers embed Bitcoin block hashes with ≥ 3 confirmations on BTC mainnet). Explorers such as explorer.emercoin.net and chainz.cryptoid.info/emer expose these AuxPoW markers so verifiers can independently attest the depth.
These operational rules make the “finality” assumption explicit and testable rather than an article of faith.

5. Authentication protocol
5.1 Roles
Prover P:
Holds sk with corresponding pk.
There exists id with Bind(id, pk) = 1.
Verifier V:
Knows id.
Has read access to D (Emer NVS + WORM).
Can recover pk via Bind.
5.2 Setup
(sk, pk) ← KeyGen(1^λ).
A WORM object for (id, pk) is published into Emer NVS and allowed to reach finality (PoS + BTC‑AuxPoW depth).
From this point on, all honest verifiers regard Bind(id, pk) = 1.
5.3 Online challenge–response
Challenge.
V samples fresh random c and sends it to P.
Response.
P computes σ := Sign(sk, c) and returns σ.
Verification.
V accepts that it is talking to id iff:
text
Auth(id, c, σ) = 1
where
text
Auth(id, c, σ) :=
  [ ∃ pk : Bind(id, pk) = 1  ∧  Verify(pk, c, σ) = 1 ].
No extra state, authority, or infrastructure appears in this definition.

5.4 Key custody and recovery expectations
The bedrock deliberately gives the individual complete custody, so loss of sk is catastrophic. To keep this tolerable in practice we require:

hardware-backed seeds (Ledger, Trezor, or Privateness HSMs) with Ed25519 deterministic derivation per RFC 8032,
split-key backups (Shamir 2-of-3 or SeedQR sharding) stored in separate jurisdictions, and
a publicly documented rotation path: publish (id, pk_new) next to the deprecated key plus a signed revocation statement in WORM so verifiers can smoothly update Bind.
We explicitly forbid institutional escrow; recovery must remain user-initiated, but nothing stops operators from scripting social recovery policies that still culminate in the individual re-signing the WORM entry.

6. Security statement
Fix an identity (id, pk) with Bind(id, pk) = 1. Let A be a PPT adversary that does not know sk.

Game:

(sk, pk) ← KeyGen(1^λ).
Publish (id, pk) as a WORM record in Emer NVS.
Give A:
description of Σ,
read access to D,
public key pk,
oracle access to Sign(sk, ·) on arbitrary messages.
Eventually A outputs (id*, c*, σ*).
A wins if:
id* = id,
Auth(id, c*, σ*) = 1, and
c*was never signed via the oracle.*
Authentication soundness.

If Σ is EUF‑CMA secure, then for all PPT adversaries A:

text
Pr[ A wins ] ≤ negl(λ).
Sketch: a winning A immediately yields a EUF‑CMA forger by forwarding its signature queries and outputting (c*, σ*) when A wins. Since Verify(pk, c*, σ*) = 1 and c*was not queried, this contradicts EUF‑CMA except with negligible probability.*

By Rompel, existence of such Σ is equivalent to existence of OWF. There is no strictly weaker hardness assumption inside the usual model that can still support this protocol.

7. Relation to Skycoin-type chains (optional anchoring)
Skycoin-type chains (Skycoin, Privateness descendants, similar UTXO chains) use:
https://github.com/skycoin/skycoin/wiki/Deterministic-Keypair-Generation-Method
secp256k1 ECDSA keypairs hashed as ripemd160(sha256(sha256(pubkey))) to form Base58 addresses, per the Skycoin address spec,<sup>[1](https://github.com/skycoin/skycoin/wiki/Technical-background-of-version-0-Skycoin-addresses)</sup> and
a UTXO model without a general script VM.
When interoperability with those chains is desired, operators may publish an additional linkage so that verifiers can correlate bedrock identities with existing wallet infrastructure. In that case we keep two cryptographic anchors for one entity:

the Ed25519 keypair (sk, pk) recorded in WORM / Emer NVS for Identity Bedrock, and
one or more Skycoin-type addresses derived from the holder’s secp256k1 keypair.
When operators want to bind those layers, they publish (id, pk, sky_addr, sky_pk) inside the WORM object plus an optional canonical self-spend transaction:

spend from the Skycoin-type address, pay back to the same address, and sign with the secp256k1 private key;
export the transaction hex and/or txid; and
wrap it as a sky_proof JSON containing { network, address, policy (canonical self-spend), txid, unsigned_tx_hex, signed_tx_hex }.
Verifiers can then check that:

the Skycoin-type address is controlled by the secp256k1 public key embedded in the proof, and
that address is the one referenced alongside pk in the WORM record.
This mapping remains optional; the bedrock authentication itself still needs only (id, pk) + Ed25519 signatures.

8. Threat model
8.1 Assumptions
Hardness: One‑way functions exist (⇔ EUF‑CMA signatures exist).
Key generation: KeyGen has access to high‑entropy sources (OS RNG, UHEPRNG, RC4OK, etc.) so sk is unpredictable.
Directory consistency: Emer’s PoS + Bitcoin‑AuxPoW consensus maintains an append‑only NVS view. Once a WORM record (id, pk) is deeply buried (including behind BTC‑AuxPoW “PoW” walls), rewriting it requires large‑scale consensus capture.
8.2 Adversary capabilities
We do not claim to prevent:

key compromise (side channels, malware, physical),
censorship or outlawing of software,
client hijack via distribution channels.
Given the assumptions, remaining impersonation strategies are:

Signature forgery
Forge (c*, σ*) with Verify(pk, c*, σ*) = 1 without access to Sign(sk, c*).
Violates EUF‑CMA ⇒ violates OWF existence.
Directory rewrite (Emer consensus capture)
Produce an alternative Emer chain whose finalized NVS state binds id to pk' ≠ pk.
Requires economic control over:
enough EMC stake to dominate PoS, and / or
enough Bitcoin hashpower pointed at Emer’s AuxPoW interface to out‑produce honest AuxPoW blocks.
Client / governance redirection
Modify clients or governance so that verifiers use a different directory D' (different NVS keys, different WORM schema).
This does not violate the mathematical definition of Auth, but can mislead users into trusting the wrong directory.*
There is no other cryptographic “hole” below the individual key; any attack that does not steal sk must either attack OWF/signatures or Emer consensus.

8.3 Client / governance redirection mitigations
Claude’s review correctly points out that policy capture via modified clients is the most realistic attack. Mitigations we require in deployments:

reproducible builds for all WORM and wallet binaries, cross-checked by at least two independent build farms;
hardware attestations (TPM/TEE quotes or MCU bootloader hashes) before a verifier trusts a client to resolve Bind();
multi-client verification—verifiers fetch the WORM object using two unrelated codebases (e.g., Go CLI plus WASM light client) and compare hashes before accepting pk; and
watch-only governors that alert the user if the namespace, schema, or MCP policy changes without an accompanying signed governance act.
These steps do not eliminate coercion, but they make redirection detectable and raise the cost of silently swapping directories.

9. Emercoin as quantified example (“weaponization”)
We do not alter Emercoin’s consensus or NVS. Instead we use them in the most adversarial way we can specify, while noting that any alternate chain with equivalent finality guarantees could host the same directory once its attack cost is quantified:

Emer’s role is reduced to one function:
maintain an append-only directory of WORM objects binding id to pk under PoS + BTC-AuxPoW.
All higher‑level trust is stripped away:
there is no PKI, no X.509 root, no IdP key hidden underneath the user’s key. The only cryptographic root of trust is the individual’s sk plus the OWF floor.
The attack surface is forced upward:
without key compromise, any attempt to recenter identity must:
break EUF‑CMA (and hence OWF), or
capture Emer consensus deeply enough to rewrite NVS history, or
redirect clients to some D'.
In that sense we “weaponize” Emercoin: we use its PoS + BTC-AuxPoW ledger and NVS not as a general config store, but as a minimal, formally specified substrate for identity bindings that remains secure even against a global Digital ID adversary living above the protocol.

Quantifying consensus capture cost.
At time t, an attacker must simultaneously (i) control > α_t of staked EMC (as observable from on-chain rich-list and staking data) and (ii) supply ≥ β_t of Bitcoin hashpower pointed at Emer’s AuxPoW. For any concrete deployment, operators can estimate α_t and β_t from public explorers and miner statistics, and then quote an explicit reorg price in EMC + BTC. Rewriting k blocks then costs on the order of (α_t · EMC_supply_locked + β_t · BTC_work(k)) where BTC_work(k) is the cumulative cost of the referenced Bitcoin blocks. We do not fix numerical values here; instead we give a parameterized cost model that implementers must instantiate with live measurements.

Operational health checks.
Implementations SHOULD track Emercoin core releases, validator churn, and observed AuxPoW submissions using standard blockchain monitoring and explorer infrastructure. If development or hashpower drops below agreed thresholds, operators can either migrate the directory to a healthier chain or increase AuxPoW depth guarantees within this same framework.

Deployment references.
Public GitHub repositories (NESSNode, PrivatenessTools, and the MCP servers) already contain the code referenced here; reproducible build scripts are under `build/` with SHA256 manifests.

10. Related work and positioning
The bedrock layer differs materially from existing decentralized identity stacks:

| System | Cryptographic primitive | Directory / consensus substrate | Attack-cost / trust anchor | Institutional key beneath user? |
| --- | --- | --- | --- | --- |
| Identity Bedrock (this work) | Ed25519 (OWF-equivalent signatures)<sup>[2](https://datatracker.ietf.org/doc/html/rfc8032)</sup> | Emercoin PoS + BTC AuxPoW NVS (pluggable to any chain with quantified finality)<sup>[1](https://emercoin.com/en/news/main-features-of-hybrid-mining/)</sup> | α_t stake + β_t Bitcoin work for k-block rewrite (§9) | No—individual key is sole root |
| Namecoin / EmerDNS | ECDSA over secp256k1 | Namecoin PoW blockchain (miner-majority consensus)<sup>[3](https://namecoin.org/docs/faq/)</sup> | 51% hashpower on Namecoin | Miners act as implicit CA |
| W3C DID / ENS | Depends on controller method (ECDSA/ECDSA+smart contracts)<sup>[4](https://www.w3.org/TR/did-core/)</sup> | Ethereum L1/L2 smart contracts + provider infrastructure (Infura, sequencers)<sup>[5](https://ens.domains/about)</sup> | Economic cost of Ethereum reorg + governance votes | DAO / registry keys can supersede user |
| Sovrin / Hyperledger Indy | Ed25519 / BLS depending on schema<sup>[6](https://sovrin.org/wp-content/uploads/Sovrin-Protocol-and-Token-White-Paper.pdf)</sup> | Permissioned validator pool (Indy ledger) | Requires trust in Sovrin stewards consortium | Yes—stewards/issuers hold governance keys |

Namecoin / EmerDNS.
These systems also bind names to values inside a blockchain, but they inherit institutional trust assumptions (miner majority) and rarely constrain the cryptographic primitive. We explicitly pin bindings to OWF-equivalent signatures and Emer’s dual-consensus cost model.
W3C DID / DID:ethr / ENS.
Most DID methods sit atop smart-contract platforms and ultimately depend on provider-specific governance (Infura RPCs, L2 sequencers, DAO votes). Identity Bedrock can publish a DID document as a WORM value, but the binding is still anchored in the Emer PoS+AuxPoW substrate with no admin keys.
Sovrin / Hyperledger Indy.
These stacks add credential schemas, revocation registries, and institutional stewards. We intentionally omit these higher layers so they can be bolted on above the bedrock without weakening the hardness floor.
Self-sovereign identity (SSI) literature.
The SSI community rightly centers individual key control, but most published systems either rely on hosted agents or add policy levers that reintroduce capture risk. Our contribution is proving that OWF + append-only directory is sufficient and necessary.

This related-work context positions Identity Bedrock as the minimal substrate onto which those richer ecosystems can safely latch without reintroducing an institutional key below the user.

11. Conclusion
Inside the classical PPT model, one-way functions are the weakest assumption under which EUF-CMA signatures (and hence public authentication) are possible. This construction:

fixes that as the hardness floor,
adds only a binding directory (id, pk) realized as WORM JSON in Emer NVS, and
defines authentication as the minimal challenge–response predicate Auth(id, c, σ).

There is nothing else “below” it to capture. Any regime that wants to control identity must do so above this bedrock, on the same terms as everyone else, or pay the price of breaking OWF-level assumptions or Emercoin’s consensus.

Identity Bedrock operationalizes that doctrine cryptographically: by eliminating all institutional keys beneath the user, we make the position expensive to assail inside the PPT + Emer assumptions while openly acknowledging that socio-legal coercion can still happen above the protocol. Any attacker that does not steal sk must either pay the consensus-capture cost described in §9 or violate OWF-level hardness assumptions.

That is the point.
