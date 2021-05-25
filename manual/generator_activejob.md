## ActiveJob

`Tapioca::Compilers::Dsl::ActiveJob` generates RBI files for subclasses of
[`ActiveJob::Base`](https://api.rubyonrails.org/classes/ActiveJob/Base.html).

For example, with the following `ActiveJob` subclass:

~~~rb
class NotifyUserJob < ActiveJob::Base
  sig { params(user: User).returns(Mail) }
  def perform(user)
    # ...
  end
end
~~~

this generator will produce the RBI file `notify_user_job.rbi` with the following content:

~~~rbi
# notify_user_job.rbi
# typed: true
class NotifyUserJob
  sig { params(user: User).returns(T.any(NotifyUserJob, FalseClass)) }
  def self.perform_later(user); end

  sig { params(user: User).returns(Mail) }
  def self.perform_now(user); end
end
~~~
