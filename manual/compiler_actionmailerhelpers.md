## ActionMailerHelpers

`Tapioca::Dsl::Compilers::ActionMailerHelpers` decorates RBI files for all
subclasses of [`ActionMailer::Base`](https://api.rubyonrails.org/classes/ActionMailer/Base.html)
that define helpers.

Like a controller, a mailer that calls `helper` or `helper_method` gets its own `HelperMethods` module, which
its views include. For example, with the following `FormatHelper` module:

~~~rb
module FormatHelper
  def format_amount(cents)
    # ...
  end
end
~~~

and the following mailer:

~~~rb
class NotifierMailer < ActionMailer::Base
  helper FormatHelper
  helper_method :unsubscribe_url

  def unsubscribe_url
    # ...
  end
end
~~~

this compiler will produce an RBI file `notifier_mailer.rbi` with the following content:

~~~rbi
# notifier_mailer.rbi
# typed: strong
class NotifierMailer
  module HelperMethods
    include ::ActionMailer::MailHelper
    include ::ActionMailer::Base::HelperMethods
    include ::FormatHelper

    sig { returns(T.untyped) }
    def unsubscribe_url; end
  end
end
~~~

A mailer whose parent mailer has helpers includes the parent's `HelperMethods` and only the helper modules it
adds, as `Tapioca::Dsl::Compilers::ActionControllerHelpers` does for controllers. Mailers have no `helpers`
proxy, so there is no `HelperProxy` class.
