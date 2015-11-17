require 'spec_helper'

describe ValidateEmail do
  describe '.valid?' do
    it 'should return true when passed email has valid format' do
      ValidateEmail.valid?('user@gmail.com').should be_truthy
      ValidateEmail.valid?('valid.user@gmail.com').should be_truthy
    end

    it 'should return false when passed email has invalid format' do
      ValidateEmail.valid?('user@gmail.com.').should be_falsey
      ValidateEmail.valid?('user.@gmail.com').should be_falsey
    end

    context 'when mx: true option passed' do
      it 'should return true when mx record exist' do
        ValidateEmail.valid?('user@gmail.com', mx: true).should be_truthy
      end

      it "should return false when mx record doesn't exist" do
        ValidateEmail.valid?('user@example.com', mx: true).should be_falsey
      end
    end
  end

  describe '.valid_local?' do
    it 'should return false if the local segment is too long' do
      ValidateEmail.valid_local?(
        'abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde'
      ).should be_falsey
    end

    it 'should return false if the local segment has an empty dot atom' do
      ValidateEmail.valid_local?('.user').should be_falsey
      ValidateEmail.valid_local?('.user.').should be_falsey
      ValidateEmail.valid_local?('user.').should be_falsey
      ValidateEmail.valid_local?('us..er').should be_falsey
    end

    it 'should return false if the local segment has a special character in an unquoted dot atom' do
      ValidateEmail.valid_local?('us@er').should be_falsey
      ValidateEmail.valid_local?('user.\\.name').should be_falsey
      ValidateEmail.valid_local?('user."name').should be_falsey
    end

    it 'should return false if the local segment has an unescaped special character in a quoted dot atom' do
      ValidateEmail.valid_local?('test." test".test').should be_falsey
      ValidateEmail.valid_local?('test."test\".test').should be_falsey
      ValidateEmail.valid_local?('test."te"st".test').should be_falsey
      ValidateEmail.valid_local?('test."\".test').should be_falsey
    end

    it 'should return true if special characters exist but are properly quoted and escaped' do
      ValidateEmail.valid_local?('"\ test"').should be_truthy
      ValidateEmail.valid_local?('"\\\\"').should be_truthy
      ValidateEmail.valid_local?('test."te@st".test').should be_truthy
      ValidateEmail.valid_local?('test."\\\\\"".test').should be_truthy
      ValidateEmail.valid_local?('test."blah\"\ \\\\"').should be_truthy
    end

    it 'should return true if all characters are within the set of allowed characters' do
      ValidateEmail.valid_local?('!#$%&\'*+-/=?^_`{|}~."\\\\\ \"(),:;<>@[]"').should be_truthy
    end
  end

  describe ".ban_disposable_email?" do
    context "domain is empty" do
      it "returns false" do
        expect(ValidateEmail.ban_disposable_email?("name@")).to eq false
      end
    end

    context "domain is not empty" do
      context "domain exists in disposable dictionary" do
        it "returns false" do
          expect(ValidateEmail.ban_disposable_email?("name@yet.another.mailnator.com")).to eq false
        end
      end

      context "domain doesn't exist in disposable dictionary" do
        it "returns true" do
          expect(ValidateEmail.ban_disposable_email?("name@domain-does-not-exists-in-dictionary.com")).to eq true
        end
      end
    end
  end

  describe ".matched_disposable_domain" do
    context "domain doesn't exists" do
      it "returns empty array" do
        domains = ValidateEmail.matched_disposable_domain("domain-does-not-exists-in-dictionary.com")
        expect(domains).to be_empty
      end
    end

    context "top level domain exists" do
      it "returns array of matched TLD" do
        domains = ValidateEmail.matched_disposable_domain("effing-spammer-that-is-not-in-the-dictionary.tk")
        expect(domains).to include "tk"
      end

      it "does not return domain name that has the blacklisted TLD in the name" do
        domains = ValidateEmail.matched_disposable_domain("playground-tk-sd-smp-sma-kuliah.com")
        expect(domains).to be_empty
      end
    end

    context "top level domain name exists" do
      it "returns array of matched domain" do
        domains = ValidateEmail.matched_disposable_domain("mailinator.com")
        expect(domains).to include "mailinator.com"
      end
    end

    context "second level domain name exists" do
      it "returns array of matched domain" do
        domains = ValidateEmail.matched_disposable_domain("another.mailinator.com")
        expect(domains).to include "mailinator.com"
      end
    end

    context "arbitrary level domain name exists" do
      it "returns array of matched domain" do
        domains = ValidateEmail.matched_disposable_domain("yet.another.effing.mailinator.com")
        expect(domains).to include "mailinator.com"
      end
    end
  end
end
