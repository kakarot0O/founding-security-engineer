# SE-5: Consumer account security (the business-to-consumer branch)

> **Grid coordinate:** SE-5, Security Engineering domain. This cell is an addition to the 2019 grid, not one of Evan Johnson's original four.
> **Why it was added:** slide 16 of the original talk is titled "It all depends", and the first thing it lists is whether the company is business-to-business or business-to-consumer. Johnson's speaker note on that slide: "this is, in my opinion, the biggest thing that will inform your priorities." The 2019 grid then services the business-to-business path thoroughly (questionnaires, public security documentation, existing commitments) and gives the business-to-consumer path nowhere to land. This cell is that landing place.
> **Load when:** the company's paying or registered users are individual people rather than companies, or the product has a consumer sign up flow open to the public, or the human asks about account takeover, credential stuffing, password reset security, login abuse, fake accounts, or notifying a large number of end users. Also load when an incident involves more than one end-user account being accessed by someone who is not the account owner.

## Read this first: whose accounts are we talking about

This cell is about the accounts belonging to the company's **customers**, the members of the public who sign up for the product. It is not about employee accounts.

Employee accounts are [cs-1-identity-and-access.md](./cs-1-identity-and-access.md). That cell is about single sign on, the identity provider, admin roles, and offboarding leavers. It protects the company from an attacker who logs in as a colleague.

This cell protects the company's users from an attacker who logs in as one of them, and protects the company from the consequences of that happening ten thousand times in one night. The controls look superficially similar (both mention multi-factor authentication, both mention session management) but the constraints are opposite. You can mandate a hardware security key for eleven employees. You cannot mandate anything for four hundred thousand strangers, most of whom reuse the same password everywhere, cannot be reached reliably by email, and will churn if you add friction. Everything in this cell is designed around that difference.

A first security hire at a consumer company who confuses the two spends a quarter hardening eleven laptops while four hundred thousand accounts sit behind a password reset flow with a guessable token. Do not be that person.

## Why this cell exists

If the company's users are individual people, the single most likely security event that will ever affect the company is a wave of account takeovers driven by passwords stolen from some completely unrelated website. It will not be a targeted attack. It will not involve a vulnerability in the company's code. It will be automated, cheap, and continuous, and the first sign will usually be a rise in customer support tickets rather than an alert.

The consequences land in places a business-to-business security hire never has to think about. Mass account takeover triggers breach notification duties in most jurisdictions, because it is unauthorised access to personal data. It generates support load that can swamp a five-person team in a day. If money or stored value is involved, it generates direct financial loss and chargebacks. And it produces press coverage of a kind that questionnaire answers never will.

Meanwhile the compliance work that dominates the default plan (security questionnaires, a public trust page, a knowledge base of answers) exists to unblock enterprise sales deals. If the company sells to consumers through an app store or a web sign up, those deals do not exist, those questionnaires do not arrive, and that work produces nothing.

## Definition of done

Good enough for a 20 to 100 person consumer startup:

- [ ] A written review of the end-user authentication surface exists, covering sign up, sign in, password reset, email change, session lifetime, multi-factor availability, and social login. Findings are in `RISK-REGISTER.md` with owners and dates.
- [ ] Password reset tokens are single use, expire in one hour or less, are generated from a cryptographically secure random source, are at least 128 bits of entropy, and are invalidated when used or when the password changes by another route.
- [ ] Changing a password or an email address invalidates every other active session for that account, and notifies the user at both the old and the new email address.
- [ ] New and changed passwords are checked against a corpus of previously breached passwords, and rejected on a match.
- [ ] Rate limiting exists on authentication endpoints at three levels: per account, per internet protocol address, and per autonomous system number or per device fingerprint.
- [ ] Users can see a list of their active sessions and devices, and can revoke them without contacting support.
- [ ] Multi-factor authentication is available to users who want it, and the recovery path for it is documented and does not silently defeat it.
- [ ] The customer support account recovery procedure is written down, scripted, and does not rely on the agent's judgement about whether a caller "sounds legitimate".
- [ ] A detection exists for the shape of a credential stuffing wave, not just for a single suspicious login, and it pages someone.
- [ ] A mass notification capability is prepared in advance: a drafted template, a tested sending path capable of the company's full user count, and a named approver.
- [ ] The company knows how it handles a data subject access request or a deletion request that arrives directly from an individual user, and how long it has to answer.

Explicitly **not** required at this size: a commercial bot management or fraud platform, device fingerprinting from a vendor, behavioural biometrics, a machine learning risk engine, passwordless-only authentication, a dedicated trust and safety team, or an identity verification vendor. Several of those become right later. None of them are the first move, and buying one early usually substitutes a dashboard for the four or five fixes that actually close the hole.

## Discovery

Everything here is read only. Do not test authentication controls against the live product until you reach the Danger zone section and have a written yes.

**The no-access case.** If you have no code access and no production access yet, you can still map most of the authentication surface as an ordinary user in about ninety minutes, using an account you create yourself on a personal email address you control. Sign up. Note whether the email address is verified before the account becomes usable. Log out and use the forgotten password flow. Look at the reset link: how long is the token, is it in the uniform resource locator path or the query string, does it still work after you use it once, does it still work an hour later, does it still work after you change the password by another route. Change the email address on the account and see whether the old address gets told. Log in from a second browser, then change the password in the first browser, and see whether the second browser is still logged in. Look for a "devices" or "sessions" or "where you are logged in" screen in account settings. Look for a two-factor option, turn it on, and then check whether the forgotten password flow lets you back in without the second factor. Every one of those is a real finding and none of them require any privilege beyond being a customer. Write the results straight into `RISK-REGISTER.md`.

Two constraints on that walk: use only your own account, and do not automate any of it. One person clicking through their own account is normal product use. A script hitting the login endpoint is an active test and needs authorisation.

**In the codebase.** The identity implementation is either a library, a hosted provider, or hand-rolled, and which one it is changes everything. Find out first:

```
grep -rniE "passport|devise|next-auth|authjs|django.contrib.auth|flask.login|spring-security|warden|omniauth" --include=package.json --include=Gemfile --include=requirements.txt --include=pyproject.toml --include=go.mod --include=pom.xml --include=build.gradle .
grep -rniE "auth0|clerk|firebase.auth|supabase|cognito|stytch|workos|okta-auth|frontegg|descope|logto|keycloak|ory|kinde" --include=package.json --include=requirements.txt --include=go.mod --include=*.env.example .
```

Then find the sensitive flows themselves:

```
grep -rniE "reset.?password|forgot.?password|password.?reset.?token|verification.?token" --include=*.py --include=*.rb --include=*.js --include=*.ts --include=*.go --include=*.java --include=*.php -l .
grep -rniE "change.?email|update.?email|new_email|pending_email" -l .
grep -rniE "bcrypt|argon2|scrypt|pbkdf2|sha1|sha256|md5" --include=*.py --include=*.rb --include=*.js --include=*.ts --include=*.go -l .
```

Three things to read closely once you have located the reset flow. First, how the token is generated: anything built from `Math.random`, `rand()`, `random.random()`, a timestamp, a sequential identifier, or the user's identifier hashed with a fixed value is guessable and is a critical finding. Look for `secrets.token_urlsafe`, `crypto.randomBytes`, `SecureRandom`, `crypto/rand`, which are the correct sources. Second, whether the token has an expiry column or field and whether anything actually checks it. A token with an expiry that is never compared is the most common variant of this bug. Third, whether the token row is deleted or marked used after a successful reset.

**In the hosted identity provider.** If authentication is outsourced, most of the answers are settings, not code. Auth0: Security > Attack Protection covers breached password detection, brute force protection, and suspicious internet protocol throttling; Authentication > Database has the password policy; Branding controls the email templates. Firebase Authentication: the Firebase console under Authentication > Settings has user actions, email enumeration protection, and the password policy, and Google Cloud Identity Platform adds multi-factor. Amazon Cognito: the user pool's Sign-in experience, Security (advanced security features, compromised credentials detection), and Messaging tabs. Supabase: Authentication > Providers, Policies, Rate Limits, and Email Templates in the project dashboard. Clerk, Stytch, WorkOS, Descope: each has an equivalent attack protection or bot protection panel. In every case, note what the setting currently is, not what the vendor is capable of. The gap between "our provider supports breached credential detection" and "it is enabled" is where the incidents live.

**In front of the application.** The rate limiting that matters is usually at the edge, not in the app. Cloudflare: check the dashboard for Security > WAF > Rate limiting rules, Security > Bots, and whether the login path has any rule at all. Amazon Web Services: check for AWS WAF web access control lists on the application load balancer or CloudFront distribution, specifically the rate-based rules and the account takeover prevention managed rule group. Google Cloud: Cloud Armor security policies attached to the load balancer. Azure: Azure Front Door or Application Gateway Web Application Firewall policies. Fastly: Next-Gen WAF or edge rate limiting. If the answer is none, that is your single highest-value finding in this cell and it is usually fixable in an afternoon.

**In the data.** You need to know the population size and shape, because it determines whether a notification is an email or a project. Ask for, or query read only if you have access: the number of registered accounts, the number active in the last thirty days, how many have a verified email address, how many have multi-factor enabled, how many have a payment method or stored value attached, and how many are children or could be. Do not export this data. Get the counts.

## Ask the human

Closed questions, answerable in one word or one number, to put to the founder, the engineering lead, or the head of support:

1. Do our users sign up themselves, or does someone at a customer company create their account for them?
2. How many registered accounts exist, and how many logged in in the last thirty days?
3. Can a user log in with a password we store, or only through Google, Apple, or another provider?
4. If both, can the same person end up with two accounts, or with a password on an account they created with Google?
5. Does an account hold money, stored value, loyalty points, or a saved payment method?
6. Has support ever restored access to an account for someone who could not use the normal reset flow? How often does that happen in a month?
7. Who at this company can change a user's email address or password from an internal tool, and is that action logged?
8. If we had to email every registered user tonight, what would we send it with, and would that system take the volume?
9. Have we ever seen a spike of failed logins? Would we know if it happened last night?
10. Could a child plausibly sign up for this product, and do we ask for an age?

Message to send the head of customer support or the support lead:

> Hi, I am doing a review of how our users' accounts can be broken into, and support is the part I understand least. Three questions when you have ten minutes. First, when someone contacts us saying they cannot get into their account and the reset email is not working, what do we currently do to decide it is really them? Second, roughly how many of those do we get a week, and is it going up? Third, what can an agent change on a user's account from our internal tool, specifically the email address and the password. No wrong answers here, I am mapping what exists, not auditing anyone.

Message to send the engineer who owns authentication:

> Hi, I am reviewing the end-user login surface and I want to start from what is already there rather than guess. Could you point me at where the password reset token is generated and validated, and tell me two things about it: how long it is valid for, and whether it is deleted after use. Second question, when a user changes their password, do their other sessions get killed. Happy to read the code myself if you just give me the file, I do not need a walkthrough.

## The walk

**Step 1. Read the reset and email-change flows and write down what they do.**
Goal: know whether the account recovery path is guessable, replayable, or silent. Do: read the code or, if authentication is hosted, read the provider settings, then record five facts (token source of randomness, token length, expiry, single use, and whether a successful reset kills other sessions). Verify: you can state each fact with a file path and line number or a screenshot of a settings page. Time: two to four hours. Who else is needed: nobody, though an engineer pointing you at the file saves an hour.

**Step 2. Turn the findings into ranked, small tickets.**
Goal: get fixes into the engineering queue while the context is fresh. Do: one ticket per finding, each with the concrete attack it enables written in one sentence, ordered by whether it allows account takeover without any user interaction. A guessable token is critical. A ninety-day expiry is high. A missing notification to the old email address is medium but cheap, so it often goes first. Verify: the tickets exist in the engineering tracker with an owner, and the same items are in `RISK-REGISTER.md` with review dates. Time: one to two hours. Who else is needed: the engineering lead, to accept them into a sprint.

**Step 3. Check new passwords against a breached-password corpus.**
Goal: stop users from choosing a password that is already in every credential stuffing list. Do: if the identity provider has this built in (Auth0 breached password detection, Cognito compromised credentials, Firebase password policy plus Identity Platform, Okta Customer Identity password health), the work is turning the setting on in a staging tenant, testing, and then production. If authentication is hand-rolled, use the Have I Been Pwned range application programming interface, which is free for this use, and which never receives the password: the client hashes the password with SHA-1, sends only the first five hexadecimal characters of the hash, and compares the returned suffixes locally. Reject on a match with a message that says the password has appeared in a public breach and is not safe, not that it is "too weak". Verify: try to register with `Password123!` in staging and get rejected. Time: half a day to two days. Who else is needed: one engineer.

**Step 4. Put rate limiting at three levels in front of the login endpoint.**
Goal: make automated credential stuffing expensive. Do: per account, per internet protocol address, and per autonomous system number or device. The reasoning matters, so hold it: per-account limits alone fail against credential stuffing because the attacker tries one password against a million accounts rather than a million passwords against one account, so no individual account ever crosses its threshold. Per-internet-protocol limits alone fail because residential proxy networks give the attacker hundreds of thousands of addresses, each used a handful of times. The pair together is what works, and adding a per-autonomous-system-number or per-device-fingerprint dimension catches the case where the traffic is distributed across addresses but concentrated in one hosting provider. Start with the edge: a Cloudflare rate limiting rule on the login path, an AWS WAF rate-based rule, or a Cloud Armor rate limit policy. Set it in log-only or count mode first and watch for a week before enforcing. Verify: the rule exists, and the count-mode metrics show it would have blocked something plausible and nothing normal. Time: one day to configure, one week of observation. Who else is needed: whoever owns the edge configuration, and product sign off before enforcement because it can affect real users.

**Step 5. Give users a session and device list they can revoke.**
Goal: let a user who suspects compromise fix it themselves, at three in the morning, without support. Do: a screen listing active sessions with approximate location, device type, and last-seen time, a revoke button per session, and a revoke-everything button. Pair it with the rule that a password change revokes all other sessions. Verify: log in on two browsers, revoke from one, confirm the other is logged out on next request rather than on next login. Time: two to five engineering days if sessions are already tracked server side, considerably more if the product uses stateless tokens with no revocation list, which is itself a finding. Who else is needed: an engineer and a designer.

**Step 6. Write the support account recovery script.**
Goal: close the social engineering path that beats every technical control above. Do: covered in its own section below. Verify: an agent who has never seen it can follow it on a live ticket without asking you a question. Time: one day to write, one hour to train. Who else is needed: the support lead, and their agreement is the whole point.

**Step 7. Build the credential stuffing detection.**
Goal: know within an hour, not within a week of support tickets. Do: covered in its own section below. Verify: you can produce the last thirty days of the relevant counters, and a threshold is set that would have fired on the worst day. Time: one to three days. Who else is needed: whoever can query the authentication logs.

**Step 8. Prepare the mass notification path before you need it.**
Goal: be able to tell forty thousand people something true within hours instead of days. Do: covered in its own section below. Verify: a dry run to an internal list of ten addresses succeeds and the template renders. Time: one day. Who else is needed: legal or the founder as approver, marketing or lifecycle for the sending path.

**Step 9. Make multi-factor available and check its recovery path.**
Goal: give the users who want protection a real option, without pretending it will get broad adoption. Do: offer time-based one-time passwords and passkeys if the platform supports them, and then, critically, test whether the account recovery flow bypasses the second factor. A very common pattern is that email-based password reset returns full access without ever asking for the second factor, which means the second factor protects nothing against an attacker who controls the email account. Decide deliberately whether recovery requires the second factor, and document the decision in `DECISION-LOG.md` either way. Verify: enable multi-factor on a test account, then attempt account recovery, and record exactly what happened. Time: two to five days if the provider supports it natively. Who else is needed: an engineer and product.

## Abuse and fraud signals, and how they differ from security alerts

A security alert says something happened that should not have happened, and the correct response is to investigate every one. An abuse signal says a rate changed, and the correct response is almost never to look at an individual case. At consumer scale you will drown if you treat the second like the first.

The signals worth having, in rough order of value:

- Failed login rate as a proportion of total login attempts, per hour. Normal products sit somewhere stable. A credential stuffing wave moves it sharply, often from single digits to most of all traffic.
- Successful logins preceded by a failure on a different account from the same source, counted per source. This is the specific fingerprint of stuffing and it is much more precise than raw failure counts.
- Password reset requests per hour. A spike here means either an attack or a broken email delivery, and both need you.
- New account creation rate, and the proportion of new accounts using disposable email domains or a single internet protocol range. Fake account waves usually precede whatever the fake accounts are for.
- Distinct accounts accessed per source address in a rolling hour. One address touching hundreds of accounts is not a user.
- Sudden changes in the geographic or autonomous-system distribution of successful logins.

Two rules keep this useful. First, alert on the aggregate, not the instance: page a human when the rate crosses a threshold, and never send an alert per suspicious login, because at a hundred thousand users that is a pager that nobody will ever look at again. Second, most abuse signals belong to product, growth, or support, not to security, and handing them over is a win rather than a loss. Your job is to make sure the account takeover slice of it reaches you. See [dr-2-top-security-signals.md](./dr-2-top-security-signals.md) for how to pick a small number of signals that actually get watched, and [dr-3-logging-consumption-model.md](./dr-3-logging-consumption-model.md) for keeping the volume affordable, because authentication logs at consumer scale are the single easiest way to accidentally quadruple a logging bill.

## The account recovery path through customer support

Every control described above assumes the attacker has to go through the product. The attacker who is any good will go through a support agent instead, because a support agent is measured on resolution time and empathy and will help a distressed person get back into their account. This is the route that beats a strong password, a breached-password check, rate limiting, and multi-factor authentication simultaneously, and at most consumer startups it is entirely undocumented.

What to give support, written as a procedure rather than a principle:

**The trust ladder.** Rank the evidence a caller can offer, and require a fixed number of steps rather than an agent's overall impression. Strong evidence: proving control of a payment method already on the account (the last four digits plus the exact amount and date of a recent charge, which the agent asks for and does not read out), proving control of a device already associated with the account, completing a challenge sent to a phone number that has been on the account for more than thirty days. Medium evidence: knowing the exact account creation date, the original signup email address if it has since changed, or the content of a recent order or activity. Weak evidence and worth nothing on its own: name, postal address, date of birth, and anything else that appears in a data broker record or an old breach. Set the bar as two strong, or one strong and two medium. Never accept weak evidence alone regardless of how convincing the caller is.

**What support never does.** Support does not change the email address on an account during a recovery conversation. It does not read out any part of an existing email address, phone number, or payment detail so the caller can confirm it, because that hands the attacker the answer. It does not disable multi-factor authentication on request. It does not accept a photograph of an identity document as proof, both because photographs of documents are trivially obtained or forged and because collecting them creates a serious data protection liability the company then owns forever. If the product genuinely requires document verification, that is a vendor decision, not something an agent improvises over chat.

**The waiting period.** For any recovery that clears the bar, the correct outcome is not immediate access. It is a notification to the address currently on the account saying that recovery has been requested, followed by a delay (twenty-four to seventy-two hours is normal) before the change takes effect, with a link to cancel. This one control turns silent account theft into a race the real owner can win. It is unpopular with support and with product because it slows a legitimate user down. Argue for it anyway, and if you lose, record the decision and its owner in `DECISION-LOG.md`.

**The escalation path.** Name the exact case that leaves support and comes to you: more than one recovery request for the same account in a week, recovery requests arriving in a burst, any account with money or stored value, and any caller who becomes pressuring or invokes urgency. Pressure is the single most reliable tell of social engineering and agents should be told explicitly that it is permission to slow down, not to speed up.

Write this as one page, agree it with the support lead, and put a copy in the support tool where agents actually work. A procedure that lives only in your `.security/` directory does not exist.

## Bulk account takeover detection

Single-account compromise and bulk compromise look completely different and need different responses, and confusing them is why companies discover waves three weeks late.

Single-account compromise is one user, one anomalous login, and usually a targeted attacker or a shared password with a partner. It arrives as a support ticket. It is handled per case.

A wave is an automated process working a list. In the logs it looks like this: a large rise in failed authentication attempts across many distinct accounts; a low but non-zero success rate, typically well under one percent, because the attacker is testing passwords stolen from another site and most do not work; a small number of attempts per account, because the attacker moves on rather than triggering per-account lockouts; source addresses spread widely but often concentrated in a few hosting or proxy autonomous systems; a uniform or scripted user agent string, or one that is too consistent to be human; and a burst of follow-on activity on the successful accounts within minutes, typically an email change, a password change, or an attempt to extract stored value.

The detection that matters is therefore a ratio and a spread, not a threshold on any single account: distinct accounts with at least one failed attempt per hour, and successful logins from sources that also produced failures on other accounts. Both can usually be computed from whatever already holds the authentication logs, whether that is a data warehouse, the application database, or a log platform, and neither needs a security product.

When a wave is confirmed, the ordering matters and it is the same ordering as any incident: contain first, and preserve evidence in parallel rather than before. Practically, containment for a wave means forcing a password reset on the affected accounts and revoking their sessions, blocking or challenging the source traffic at the edge, and temporarily raising friction on the login path. All of those affect real customers, so all of them need an explicit yes from a named decision maker before you touch anything, and the fastest way to get that yes is to have agreed in advance who gives it. Open an incident file under `incidents/` using the process in [dr-1-incident-response-plan.md](./dr-1-incident-response-plan.md) the moment you suspect a wave, not when you have proved one.

## Mass notification readiness

If forty thousand accounts are affected, you cannot write forty thousand emails on the day, and you will not have the calm to write even one well. Notification obligations in most jurisdictions run to seventy-two hours from awareness for the regulator, and to "without undue delay" for the individuals, which in practice means days, not weeks. The work is therefore done in advance, while nothing is on fire.

Prepare four things:

1. **A drafted template** with the facts left blank: what happened, when, what data was involved, what the company has already done, exactly what the user must do now (the single clearest instruction is usually that their password has been reset and they must set a new one), what the company will never ask them for, and where to get help. Keep it under three hundred words. Put it in `drafts/`.
2. **A tested sending path** that can actually deliver to the entire user base within a few hours. Transactional email providers apply rate limits and reputation controls, and a sudden send of four hundred thousand messages from an address that normally sends four hundred will be throttled or filtered. Find out now what the account's actual sending rate limit is, and whether the marketing platform or the transactional provider is the right path. Do a dry run to an internal list.
3. **A named approver and a named sender.** One person who says the words go out, usually a founder or the general counsel, and one person who presses send. Both with a backup. In `SECURITY-STATE.md`.
4. **A support surge plan.** A notification to forty thousand people generates a support wave within an hour. Agree with support in advance what the standard reply is, whether a help page goes up at the same time, and who writes it.

Two things people get wrong under pressure. Do not send the notification from a new domain or a lookalike address that you set up for the occasion, because it is indistinguishable from a phishing email and will train users to click on the real thing. Do not include a login link in the notification for the same reason: tell people to go to the site the way they normally do.

Publishing anything externally, including a notification to users and a status page post, is one of the actions that always needs an explicit human yes. Draft freely. Send nothing on your own authority.

## The privacy surface that comes with consumer accounts

Consumer accounts change the shape of privacy work in one specific way: the requests come from individuals rather than through a customer's procurement or legal team. That changes both the volume and the tooling.

In a business-to-business company, a data subject access request arrives once a quarter, through a customer, in writing, with a contact who is used to process. In a consumer company it arrives through a support form, in whatever words the user chose, potentially hundreds of times a month, and the clock starts anyway. The obligations are real: under the General Data Protection Regulation the response window is one month, extendable in limited circumstances, and under the California Consumer Privacy Act it is forty-five days with a possible extension. Deletion requests are the harder half, because deleting a user from the production database does nothing about the analytics platform, the data warehouse, the email marketing tool, the support tool, and the backups.

The minimum that makes this survivable: know which systems hold user data (this is the data inventory in [co-4-data-inventory-and-framework.md](./co-4-data-inventory-and-framework.md), and a consumer company needs it earlier and more concretely than a business-to-business one), have a documented and preferably semi-automated path to fulfil a request across all of them, log every request with its date received and date answered so you can prove timeliness, and verify the requester's identity before disclosing anything, because an access request is itself an account takeover vector if you answer it for whoever asks. Use the same trust ladder as the support recovery procedure.

If the product could plausibly attract children, this becomes materially more serious. In the United States the Children's Online Privacy Protection Act applies to under-thirteens and carries per-violation penalties. In the United Kingdom the Age Appropriate Design Code applies, and several other jurisdictions have equivalent rules. The questions to answer are narrow and factual: does the company ask for an age at signup, what does it do with an account that self-reports as underage, does it market anywhere that reaches children, and does it have any features (public profiles, direct messaging, user-generated content) that make the exposure worse. This is a legal determination, not a security one. Your job is to surface it clearly, put it in `RISK-REGISTER.md`, and make sure a founder makes the call rather than nobody making it.

## Decision points

**Is this company actually business-to-consumer?** Default: treat it as consumer if members of the public can create an account without anyone at the company approving it, and if individuals rather than companies pay. The condition that changes it: many companies are both, in which case run this cell for the consumer product and the compliance cells for the enterprise one, sized by which side carries the revenue. A product-led business-to-business company with self-serve signup sits in the middle and needs a thin version of both.

**Force a password reset on suspected accounts, or challenge them at next login?** Default: force the reset for accounts you have concrete evidence were accessed, because it is unambiguous and it ends the attacker's access immediately. The condition that changes it: if the suspected population is very large and the evidence is weak, a step-up challenge at next login is far less disruptive and buys time. Never do either without an explicit yes from the named decision maker, because both are customer-visible.

**Enforce multi-factor for all users, or offer it?** Default: offer it, and enforce it only for a defined high-risk subset (accounts with stored value, accounts with administrative capability inside the product, accounts that have already been compromised once). The condition that changes it: if the product holds money or is a target of regulation that requires strong customer authentication, enforcement is the answer and product will have to absorb the friction. Blanket enforcement on a consumer base without a tested recovery path produces mass lockout, which is an outage.

**Build detection or buy a bot management product?** Default: build the two or three counters described above from logs you already have, because it takes days rather than a procurement cycle and it teaches you what normal looks like. The condition that changes it: sustained, adaptive, high-volume attack traffic that survives edge rate limiting. Bot management then costs roughly five to thirty thousand United States dollars a year at startup volumes, and Cloudflare's bot management and AWS's account takeover prevention managed rule group are the cheapest credible entries because they sit on infrastructure the company probably already has.

**Do the authentication fixes yourself, or hand them to engineering?** Default: hand them over, with a precise ticket and the attack written out. The condition that changes it: if you are an engineer and the team is genuinely blocked, write the patch, but put it through normal review. Security code that bypasses review is how the reset flow got broken in the first place.

## Danger zone

Every action in this list requires an explicit yes from a named human before you do it, every time. The only exception is the single named one at the end of this section.

- **Forcing a password reset, revoking sessions, or locking any user account.** This is customer-visible and it generates support load immediately. Getting the affected population wrong locks out people who were never compromised. Agree the population, the message, and the support plan before anyone runs the query.
- **Enabling or enforcing multi-factor authentication for a population of users.** Without a tested recovery path this locks out everyone who loses their device, and at consumer scale that is a permanent percentage of the base, not a handful of tickets.
- **Enforcing a new rate limit or a bot challenge on a live login path, or blocking a source address or range at the edge.** Set it too tight and you have built a self-inflicted outage that looks exactly like a successful denial of service. Edge blocking in particular feels reversible and is not, because at consumer scale a single carrier-grade address range can be tens of thousands of legitimate users, and none of them will tell you: support hears about it two days later. Always run in count or log-only mode first, always have the rollback command ready, and always tell support before it goes live.
- **Any active test against the company's own authentication, including credential stuffing simulations, password spraying, brute forcing a reset token, or running a scanner against the login page.** Written authorisation from someone empowered to give it, in advance, in every case. Testing your own company's production login without that is still unauthorised access, and it also risks locking out real users and polluting the very signals you are trying to build.
- **Anything touching customer data, including exporting a list of affected accounts, querying user records beyond counts, or pulling email addresses for a notification.** Ask, get a yes, minimise what you pull, and record what you accessed in `ACCESS-LOG.md`.
- **Sending any notification to users, publishing a status page update, or posting anything externally about an incident.** Draft it, get approval, let the named sender send it.
- **Telling a customer, a partner, or a journalist that a control exists or will exist by a date.** That is a commitment, and it goes through [co-3-existing-commitments.md](./co-3-existing-commitments.md).
- **Turning on verbose authentication logging or a new log source.** At consumer volume this can multiply a logging bill in a day. Estimate first, get a yes on the cost.
- **Rotating any signing key, session secret, or token-signing credential that production uses.** It logs out every user at once. That is sometimes exactly the right containment action, and it still needs an explicit yes from the person who owns that consequence.

During a **declared** incident, and only where the standing pre-authorisation in step 10 of [dr-4-company-comms-channel.md](./dr-4-company-comms-channel.md) was agreed in advance and recorded in `DECISION-LOG.md`, two containment actions may proceed on the incident commander's authority: revoking the sessions and refresh tokens of a named compromised end-user account, and revoking a third party OAuth (open authorisation) grant. Those two and nothing else, and if that pre-authorisation was never agreed there is no exception and you ask. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.

One ordering rule that people get backwards under pressure: evidence preservation never blocks containment. If accounts are being taken over right now, stop it, and capture what you can in parallel. What must not happen during containment is rebooting or terminating the host, deleting the malicious content, or closing the account under investigation, because those destroy the evidence without gaining anything.

## Do not do this yet

- **Do not buy a fraud, bot management, or identity verification platform in your first quarter.** The three or four configuration fixes in this cell remove most of the exposure for close to nothing, and you cannot evaluate a fraud vendor sensibly until you know your own baseline rates.
- **Do not build device fingerprinting yourself.** It is a deep specialty, it has real privacy consequences, and a half-built version produces confident nonsense.
- **Do not attempt to eliminate passwords entirely.** Passkeys are genuinely better and worth offering, but a consumer migration away from passwords is a multi-quarter product programme with a long tail of users on devices that do not support it.
- **Do not take ownership of trust and safety.** Fake accounts, spam, harassment, and content moderation overlap with this cell and are not it. Help define the signals, then hand them to product or operations.
- **Do not write a public security page or a questionnaire knowledge base yet if the company is purely consumer.** See the plan adaptation below.
- **Do not run a simulated credential stuffing attack "to prove the risk".** The finding is provable from a code read and a settings screenshot. Running the attack is the one move that can turn a legitimate review into an incident with your name on it.
- **Do not start collecting identity documents to solve the support recovery problem.** It creates a much larger liability than the one it solves.

## Evidence to capture

Into `SECURITY-STATE.md`: SE-5 status (unknown, none, partial, done, or n/a), the registered and active user counts with the date they were taken, the authentication implementation (library, hosted provider by name, or hand-rolled), whether breached-password checking is on, whether edge rate limiting exists on the login path, whether users can revoke their own sessions, whether multi-factor is offered and the adoption number, and the named approver and sender for a mass notification. Move to `done` only when you have the evidence, and to `n/a` only with a written reason such as "accounts are provisioned exclusively by customer administrators, no public signup exists".

Into `RISK-REGISTER.md`: one row per authentication finding, with the attack it enables in plain language, an owner, and a review date. Deferred items live here, not in a code comment.

Into `DECISION-LOG.md`: the multi-factor enforcement decision, the recovery-bypasses-second-factor decision, the support waiting-period decision, and the rate limit thresholds with the reasoning behind each. These are the ones you will be asked to justify later.

Into `ACCESS-LOG.md`: every time you query production user data, with what you ran, why, and who approved it.

Into `incidents/INC-<YYYY>-<NNN>-<slug>.md`: any account takeover wave, from first suspicion.

Into `drafts/`: the mass notification template and the support recovery procedure.

What a future auditor, acquirer, or enterprise customer will ask for: proof that password storage uses a modern algorithm with per-user salting, proof that reset tokens expire and are single use, evidence of rate limiting on authentication, the documented account recovery procedure, evidence that multi-factor is available, the log of data subject requests with response times, and the incident record for any takeover event with the notification that went out. Capturing these as you go costs minutes. Reconstructing them a year later costs weeks.

## Cost and effort

The review itself, steps 1 and 2, is one to three days of your time and no money.

Breached-password checking is free: built into most hosted identity providers at no extra charge, or through the Have I Been Pwned range application programming interface which is free for password checking. Half a day to two days of engineering.

Edge rate limiting is free or near free on infrastructure the company already has. Cloudflare's free tier includes basic rate limiting rules, and paid plans start around twenty United States dollars a month. AWS WAF is a few dollars per web access control list per month plus request charges, typically tens of dollars at startup volume, and the account takeover prevention managed rule group adds roughly ten dollars a month plus per-request pricing. Google Cloud Armor is comparable. One day of configuration.

Session and device management is engineering time only, two to five days if sessions are already server-side.

Multi-factor is usually included in the identity provider's price, though some charge per monthly active user for it, which at consumer scale is the one line item that can genuinely surprise you. Check before promising it.

The support procedure, the detection, and the notification readiness are your time: roughly one week in total, no spend.

Bot management, when it is genuinely the answer and not before, runs from around five thousand to thirty thousand United States dollars a year at startup volumes. Identity verification vendors charge per check, typically one to three dollars, which only makes sense for high-value recovery and never as a default.

Total for everything in this cell: two to four weeks of a mixed security and engineering effort, and under one thousand dollars a year in new spend for most companies.

## Failure modes

| What goes wrong | The early tell | Recovery |
| --- | --- | --- |
| Rate limits set too tight and legitimate users are blocked | Support tickets about "cannot log in" rise within an hour of the rule going live | Roll back immediately, return to count mode, and raise the threshold based on the observed distribution rather than a guess. Always deploy these with the rollback command already written. |
| Multi-factor enforced without a working recovery path | A steady stream of permanently locked-out users, and support quietly inventing a bypass | Pause enforcement, build the recovery path, then re-enable. The bypass support invented is now your real authentication control, so find it and fix it first. |
| Second factor is silently defeated by password reset | Nobody notices, because it works perfectly for legitimate users | Test recovery against a multi-factor account explicitly. This one is invisible until an attacker uses it. |
| Detection built on a threshold that never fires | Months pass with no alerts and everyone assumes things are quiet | Backtest against historical logs. If the rule would not have fired on the worst day in the last ninety days, the threshold is wrong. |
| The credential stuffing wave is found via support tickets, weeks late | Support mentions an increase in "I have been hacked" contacts | Treat this as the trigger to build step 7 properly, and ask support to route that ticket category to you automatically. |
| Notification email cannot be sent at volume on the day | Discovered during the incident, not before | Test the sending path now. Ask the email provider to raise the limit in advance and document the process for an emergency send. |
| Support becomes the account takeover path | Recovery volume rises, or the same account is recovered twice in a week | Implement the waiting period and the escalation triggers. Audit the last ninety days of recoveries for repeats. |
| Deletion requests are fulfilled in the production database only | A user complains they still receive marketing after deleting their account | Map every downstream system in the data inventory and build the deletion path across all of them. |
| The whole quarter goes into compliance work that nobody asked for | No questionnaire has arrived and no deal is blocked, but the plan is full of compliance steps | Re-plan. See the adaptation note below. |

## Plan adaptation for a business-to-consumer company

This section changes the default sequence, and it exists because the default sequence was built for a business-to-business company.

When the intake in [00-cold-start.md](./00-cold-start.md) and [02-intake-questions.md](./02-intake-questions.md) establishes that the company sells to consumers:

1. **This cell moves forward, into Gate B in [03-90-day-plan.md](./03-90-day-plan.md).** The authentication review and the reset-token fix belong in the stop-the-bleeding phase, alongside identity and secrets, because they are the same class of problem: a known, cheap, high-consequence hole.
2. **[co-2-questionnaire-knowledge-base.md](./co-2-questionnaire-knowledge-base.md) drops out of the first 90 days unless a questionnaire has actually arrived.** Building a knowledge base of answers for questionnaires that will never come is the clearest example of the framework generating work rather than findings generating work. If one arrives, load that cell then. Mark the cell `n/a` with the written reason "no enterprise sales motion, no questionnaires received", and revisit if the company adds a business tier.
3. **[co-1-public-security-docs.md](./co-1-public-security-docs.md) shrinks to two artifacts rather than a trust centre:** a security contact address that a researcher can find (which belongs with [se-4-bug-bounty-and-disclosure.md](./se-4-bug-bounty-and-disclosure.md) anyway) and a short, honest account security help page telling users how to protect their own account and what the company will never ask them for. That page is worth more to a consumer company than a full trust centre, and it takes an afternoon.
4. **[co-4-data-inventory-and-framework.md](./co-4-data-inventory-and-framework.md) stays and gets more important, not less.** The driver changes from a customer contract to privacy law and the volume of individual requests.
5. **The metrics in [05-metrics-and-comms.md](./05-metrics-and-comms.md) change.** Drop questionnaire turnaround time and questionnaires completed, which measure nothing here. Report instead: account takeover rate (confirmed compromised accounts per ten thousand active accounts per month), support-driven account recovery volume and its trend, the proportion of login attempts that fail, multi-factor adoption among users who have it available, and time from the start of a takeover wave to detection. These are the numbers a consumer founder actually feels, which means they are the numbers that get you the engineering time.

One caution that outranks all five points above. None of this is a reason to work this cell mechanically. If the intake reveals that the consumer product is a small side experiment with two hundred users and the real business is an enterprise contract closing next month, then the enterprise compliance work is the correct priority and this cell waits. Findings drive the plan. Ask what this company actually looks like, and let that decide.

## Related cells

- [cs-1-identity-and-access.md](./cs-1-identity-and-access.md): the employee-facing counterpart to this cell. Read the opening of both if there is any confusion about which accounts you are protecting.
- [se-1-sdlc-and-design-reviews.md](./se-1-sdlc-and-design-reviews.md): the authentication fixes here go through the normal engineering process, and future changes to login flows should trigger a design review.
- [se-3-secrets-and-keys.md](./se-3-secrets-and-keys.md): covers the session-signing keys and token secrets whose rotation logs out every user.
- [se-4-bug-bounty-and-disclosure.md](./se-4-bug-bounty-and-disclosure.md): authentication flaws are the most common thing an external researcher will report, so the disclosure path matters more at a consumer company.
- [dr-1-incident-response-plan.md](./dr-1-incident-response-plan.md): a takeover wave is an incident and uses that process, including the notification decision.
- [dr-2-top-security-signals.md](./dr-2-top-security-signals.md): where the credential stuffing detection lives alongside the other signals you actually watch.
- [dr-3-logging-consumption-model.md](./dr-3-logging-consumption-model.md): consumer authentication logs are the fastest way to an unexpected logging bill.
- [dr-4-company-comms-channel.md](./dr-4-company-comms-channel.md): the internal channel that carries the account security guidance users will ask support about.
- [co-4-data-inventory-and-framework.md](./co-4-data-inventory-and-framework.md): the data inventory that makes deletion requests and breach notification scoping possible.
- [co-3-existing-commitments.md](./co-3-existing-commitments.md): anything already promised in the privacy policy or terms of service about account security is a commitment you now own.
- [03-90-day-plan.md](./03-90-day-plan.md): where this cell lands on the calendar, and what it displaces.
- [05-metrics-and-comms.md](./05-metrics-and-comms.md): the metric substitution described above.
- [07-modern-cells.md](./07-modern-cells.md): covers the modern additions to the grid, including the abuse surface that artificial intelligence features add to a consumer product.
