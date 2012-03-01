require_relative 'helper'

class MailBuilderTest < MiniTest::Unit::TestCase

  def test_recipient_encoding
    assert_equal('to: bernerd@wieck.com', mailer(:to => 'bernerd@wieck.com').build_headers.strip)
    assert_equal('to: "=?utf-8?Q?Bernerd?=" <bernerd@wieck.com>', mailer(:to => '"Bernerd" <bernerd@wieck.com>').build_headers.strip)
  end

  def test_multiple_recipient_encoding
    desired_to = 'to: "=?utf-8?Q?Bernerd?=" <bernerd@wieck.com>, "=?utf-8?Q?Adam?=" <adam@wieck.com>'
    assert_equal(desired_to, mailer(:to => '"Bernerd" <bernerd@wieck.com>, "Adam" <adam@wieck.com>').build_headers.strip)
    assert_equal(desired_to, mailer(:to => ['"Bernerd" <bernerd@wieck.com>', '"Adam" <adam@wieck.com>']).build_headers.strip)
  end

  def test_all_addresses_are_encoded
    %w(from to cc bcc reply-to).each do |field|
      assert_equal("#{field}: \"=?utf-8?Q?Bernerd?=\" <bernerd@wieck.com>", mailer(field => '"Bernerd" <bernerd@wieck.com>').build_headers.strip)
    end
  end

  def test_rfc2045_encode
    assert_equal('<a href=3D"http://google.com">Google</a>', mailer.rfc2045_encode('<a href="http://google.com">Google</a>'))
  end

  def test_rfc2047_encode
    assert_equal("=?utf-8?Q?This_+_is_=3D_a_=5F_test_*_subject?=", mailer.rfc2047_encode("This + is = a _ test * subject"))
    assert_equal("=?utf-8?Q?=C3=A4=C3=A4=C3=A4=C3=B6=C3=B6=C3=B6?=", mailer.rfc2047_encode("\303\244\303\244\303\244\303\266\303\266\303\266"))
  end

  def test_empty_mailer_throws_no_errors
    assert mailer.to_s
  end

  def mailer(options = {})
    Harbor::Mail::Builder.new(options)
  end

end
