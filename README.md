GitHub-Reminders
================

Server side app and Webhook to parse GitHub Issue Comments and generate scheduled Email reminders based on the parsed comment


Sinatra + GitHub OAuth + Qless + Chronic gem + Email = GitHub-Reminders

Worker (executes scheduled emails): https://github.com/StephenOTT/GitHub-Reminders-Worker

## Reminder Syntax

While in a Issue make a comment with the following:

- `:alarm_clock: Next Friday at 3:05pm` #=> :alarm_clock: Next Friday at 3:05pm

- `:alarm_clock: [Date/Time] | [Reminder Comment]`

![screen shot 2014-05-07 at 10 47 57 pm](https://cloud.githubusercontent.com/assets/1994838/2911418/59a5874e-d65b-11e3-891c-48517de66e82.png)


Notes:

1. The Reminder Syntax must be at the beginning of the Issue Comment.

2. The goal is to treat the comment as a "record" containing the Reminder.

3. The separator between the Date and time of the reminder and the "reminder comment" is the pipe character `|` (above the enter/return key).  Future versions will support Reminder Comments in new lines without the need for the `|` pipe.

4. The DateTime is parsed by the Chronic gem.  Any date and time format the Chronic gem can parse is supported.

5. GitHub.com provides all timestamps as a UTC timezone, therefore you will need to choose your timezone in your "profile" in the Sinatra app.  The reminder's Date/Time will parsed using your profile's timezone. 

6. The Sinatra app will provide the ability to view your scheduled reminders for each repo/issue queue and a set number of "completed" reminders.

7. MailGun.com Email API is being used to send emails.  The code has been designed to be agnostic of the specific email service.


## Features to be built

1. Once hook is added to the repo, any user can signup and receive notifications


## Process Overview:

![process overview](https://cloud.githubusercontent.com/assets/1994838/3020826/d0988818-dfa4-11e3-948d-731ab83cd81d.png)
