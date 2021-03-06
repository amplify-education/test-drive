require 'spec_helper'
include Test::Drive::GitHelper

describe 'GitHelper' do
  describe '#create_patch' do
    it 'raises an error when patch is not generated' do
      expect(self).to receive(:sh).twice.and_return 64
      expect { create_patch "temp-patch" }.to raise_error IOError
    end
  end

  describe '#delete_patch' do
    it 'deletes the patch file' do
      filename = 'tmpfile'
      File.new filename, 'w'
      expect(File).to exist filename

      delete_patch filename
      expect(File).not_to exist filename
    end
  end
end
