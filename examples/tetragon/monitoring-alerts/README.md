# Configuring Log-based Alerts
Creating a [log-based alert](https://cloud.google.com/logging/docs/alerting/log-based-alerts#policy_structure) requires you to write the policy in JSON (which is not fun, but alternatively you can create this through Terraform).

I've included a sample policy and equivalent in Terraform where I used the [`join`](https://developer.hashicorp.com/terraform/language/functions/join) function to format the filter into a much more organized format.


### Notification Channel (recommended)
You will need to create a [Notification Channel](https://cloud.google.com/monitoring/support/notification-options) first as the associated *CHANNEL_ID* will have to be passed into the alert policy if you want to receive notifications (via email, Slack, PagerDuty, etc.).  This is *optional* but highly recommended unless you have a team that watches for notifications around the clock 

### Alert Policy 
```sh
gcloud alpha monitoring policies create --policy-from-file="alert-blocked-tracingpolicies.json
```

#### Notes
- `conditions` is a list of conditions for the policy
- `filter` is (more or less) the format of what you would put into a [Log Explorer](https://cloud.google.com/logging/docs/view/logs-explorer-interface) query.   
- `notificationRateLimit` is how often notifications are sent out
- `combiner` how to combine the results if there are multiple conditions in the list (i.e. `OR` or `AND`) 
