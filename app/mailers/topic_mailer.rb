# coding: utf-8  
class TopicMailer < BaseMailer  
  def new_reply(reply_id,to)
    reply = Reply.find_by_id(reply_id)
    return false if reply.topic.blank?
    @topic = reply.topic
    @reply = reply
    mail(:to => @topic.user.email, :subject => "Re:#{@topic.title}")
  end
  
  def self.got_reply(reply)
    @reply = reply
    @topic = Topic.find_by_id(@reply.topic_id)
    emails = []
    User.where(:_id.in => @topic.follower_ids).excludes(:_id => @reply.user_id).each do |u|
      # 跳过，如果用户不允许发邮件
      #next if u.mail_new_reply == false
      emails << u.email
    end
    # 加上话题发起者
    emails << @topic.user.email
    # 去掉回复者
    emails.delete(@reply.user.email)
    # 唯一
    emails.uniq!
    emails.each do |email|
      ::TopicMailer.new_reply(@reply.id,email).deliver
    end
  rescue => e
    Rails.logger.error("TopicMailer.got_reply failed. #{e}")
  end
  
  class Preview < MailView
    # Pull data from existing fixtures
    def new_reply
      reply = Topic.first.replies.last
      ::TopicMailer.new_reply(reply.id, reply.user.email)
    end
  end
end