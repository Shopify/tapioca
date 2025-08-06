## ActionMailer

`Tapioca::Dsl::Compilers::ActionMailer` generates RBI files for subclasses of
[`ActionMailer::Base`](https://api.rubyonrails.org/classes/ActionMailer/Base.html).

For example, with the following `ActionMailer` subclass:

~~~rb
class NotifierMailer < ActionMailer::Base
  def notify_customer(customer_id)
    # ...
  end
end
~~~

this compiler will produce the RBI file `notifier_mailer.rbi` with the following content:

~~~rbi
# notifier_mailer.rbi
# typed: true
class NotifierMailer
  sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
  def self.notify_customer(customer_id); end
end
~~~
