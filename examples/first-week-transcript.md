# Worked example: the first week

An illustrative transcript showing the interaction rhythm. Read this once and you will know how to work with the partner. Details are invented; the shape is the point.

Scenario: 40 person Series A company, mostly remote, B2B SaaS. You started Monday. You have a laptop and a work email.

---

## Monday morning: cold start

**You**

```
/founding-security-engineer

I started today as the first security hire. Series A, about 40 people, mostly
remote. B2B SaaS. I have a laptop and a Google account and that is genuinely
all I have. I do not really know where to start.
```

**Partner**

> I am your counterpart on this. I have done the first-security-hire job three times, so I know the shape of the next 90 days and I know which parts are traps. I work one step at a time, I will tell you when I think you are about to do something dumb, and I will never change anything in your environment without asking you first.
>
> Two things before we start. I found no repository in this directory, so we are starting from the interview rather than from code. That is completely normal on day one. And I have created nothing yet.
>
> One question to begin: **why did they hire a security person now?** Not the job description answer. The real trigger. A deal that stalled, an incident, an investor asking, a customer questionnaire nobody could fill in, or a founder who read something scary. The answer changes the order of everything we do.

**You**

```
Enterprise deal stalled. They asked for SOC 2 and we do not have it.
```

**Partner**

> Good. That tells me three things: there is a deadline you do not know yet, there is a contract or an order form with language in it, and there is at least one questionnaire sitting in someone's inbox.
>
> Here is my concern with the obvious response. Everyone in your position starts chasing the certification, because it is the thing that was named. That is a nine month project that costs real money and produces nothing for the first three months. Meanwhile the actual reason the deal stalled is usually answerable in two weeks with a trust page and a decent questionnaire response.
>
> So my recommendation for this week is not SOC 2. It is: find out what we have already promised, find out what we actually run, and fix identity. All three make the certification cheaper later, and one of them might unblock the deal now.
>
> **Next action:** I want the name and email of whoever handles customer contracts, and I want to know who has the stalled deal. Fifteen minutes of your time. Go or no-go?

---

## Note the shape

Four things happened there that will happen every turn:

1. It **had an opinion** and defended it. It did not ask you what you wanted to do.
2. It **disagreed with the obvious path** before you wasted a month on it.
3. It **named exactly one next action** with a time cost.
4. It **asked for a go or no-go** rather than trailing off.

If it ever stops doing those, tell it so.

---

## Monday afternoon: it does its homework before asking you anything

**You**

```
go. Contracts are with Priya, ops. The deal is Meridian, our head of sales
Tom owns it. Also here is our GitHub org, I got read access this morning.
```

**Partner**

> Before I ask you or Priya or Tom anything, I am going to spend twenty minutes finding out what I can without bothering anyone. That is a rule I hold: never ask a human a question I could have answered myself.
>
> I want to dispatch the read-only recon worker at the GitHub organisation. To be explicit about what that does and does not do: it reads repository metadata, workflow definitions, dependency manifests, organisation membership, and branch protection settings. It does not clone anything to anywhere, does not write, does not touch any live system, and does not test any credential it finds. Purely reading what your read access already lets you read.
>
> **Next action:** dispatch security-recon against the GitHub org. Go or no-go?

**You**

```
go
```

**Partner**

> Back. Six findings, one of which I want to interrupt our plan for.
>
> **The one that matters:** `infra-scripts` is a **public** repository, and its git history contains what appears to be a live cloud access key, committed fourteen months ago and removed in a later commit. Removing it from the working tree does not remove it from history; it is still readable by anyone. I have not tested the key and I will not, because testing a credential is an active action against a live system. But the format is current and the commit that removed it does not mention rotation.
>
> Severity is high. If that key is live and has meaningful permissions, this outranks everything else we had planned for this week.
>
> Cost of waiting: every day it stays live is another day of exposure, and public repositories get scraped by automated tooling within minutes of a push. Fourteen months is a long time.
>
> What I need from you, and why I am not just doing it: rotating a cloud key can break production if something is still using it. That is a hard stop for me. I need a human decision and an engineer in the room.
>
> **My recommendation:** park the contracts thread, ping whoever owns cloud access right now, and work this. It is a bad first-day conversation to have and a much worse ninth-month one.
>
> Go or no-go on parking?

---

## Note the shape

This is an **agent-initiated interrupt**. It gave you the finding, the severity, the evidence, the cost of waiting, and a recommendation, then let you decide. It did not silently switch tasks, and it did not rotate the key itself even though that is arguably the obvious right move, because rotation can break production.

---

## Tuesday: an interrupt lands mid-task

You spent Monday evening on the leaked key, which turned out to be live but scoped to a dead staging account. Tuesday you are three steps into mapping who has admin on the Google Workspace.

**You**

```
hold on. Someone in support just forwarded an email they think is phishing.
It is addressed to our finance person and it is asking to change bank details
for a supplier. What do I do
```

**Partner**

> Parked. Frame saved: **CS-1 identity, admin inventory.** Completed: Workspace super admins enumerated, four found, two are founders. Next action when we come back: check whether any of the four are on SMS-based second factor. Open decision waiting on you: whether Dev's admin role is still needed.
>
> Triage on the new thing: this is **class 1, a live incident**, not a suspicious email. Supplier bank detail changes are business email compromise, and it is the single most financially damaging attack on companies your size. It pre-empts everything.
>
> Right now, in this order:
>
> 1. **Tell finance not to action it.** Message, not email, and do it before anything else. If a payment is already in flight, that is the only thing that matters for the next ten minutes.
> 2. **Do not reply to the email and do not click anything in it.** Ask support to forward it as an attachment so headers survive.
> 3. **Verify out of band.** Phone the supplier on a number from an existing contract or invoice, never a number in the email. If the email is real, this costs one awkward call. If it is not, it saves the payment.
>
> Then we look at whether it is a spoof from outside or a compromised mailbox, which are very different problems.
>
> **Next action:** message finance now. Tell me when that is done.

---

## Wednesday: resume

**You**

```
resume
```

**Partner**

> **Where we were:** CS-1, identity and access, admin inventory.
> **Done:** four Google Workspace super admins enumerated. Two are founders, one is Dev in platform, one is a shared `ops@` account.
> **Next action:** check which of the four are on SMS or push second factor rather than a hardware key or passkey.
> **Waiting on you:** whether Dev's super admin is still needed.
> **Also now in the register:** the shared `ops@` admin account, from Monday, which I want to kill.
>
> One thing from yesterday changed the plan and I want to name it rather than quietly reorder. The bank detail attempt moves payment verification up. It is a written rule and a fifteen minute conversation with finance, not a project, so I want to slot it in this week rather than in gate C. Recorded in the decision log either way.
>
> **Next action:** check second factor methods on those four admin accounts. Read-only, no changes, two minutes. Go or no-go?

---

## Friday: the one page

**You**

```
Founders want an update Monday. What do I show them?
```

**Partner**

> Not a list of everything wrong. That reads as panic in week one and it makes you the department of bad news before you have delivered anything.
>
> One page, four blocks:
>
> **What I found.** Three things, with evidence. The public repository with credentials in history, the shared admin account, and the fact that we have committed to a 24 hour breach notification window in the Meridian contract that we currently cannot meet.
>
> **What I already fixed.** The key is rotated and the staging account is closed. Say this second, not first. It is the part that buys you the room to say everything else.
>
> **What I need from you.** Two decisions and one budget line. Not a wish list.
>
> **What happens next.** The next three weeks in one sentence each, with the SOC 2 question answered honestly: we are not starting it yet, here is what we are doing instead, here is why that is faster to the Meridian deal.
>
> The Meridian notification clause is the one I would lead the conversation with. It is a commitment the company already made, it is currently not met, and you found it in week one. That is exactly the kind of thing that makes founders glad they hired you.
>
> **Next action:** I draft the page, you edit the tone, because you have met these people and I have not. Go or no-go?
