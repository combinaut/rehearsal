require 'spec_helper'

describe Rehearsal::Middleware do

  let(:app) { MockRackApp.new }
  let(:env) { app.env }
  let(:middleware) { described_class.new(app) }
  let(:mock_request) { Rack::MockRequest.new(middleware) }
  let(:request) { Rack::Request.new(env) }
  let(:record) { create_record }

  let(:request_url) { "/pages/my_page?preview_url=#{CGI.escape(preview_url)}" }
  let(:preview_url) { '/pages/preview_page' }

  before do
    app.mock(request_url)
    app.mock(preview_url)
  end

  def execute_request(path = request_url)
    mock_request.patch(path)
  end

  context 'during a rehearsal' do
    before { allow(Rehearsal::Configuration).to receive(:trigger).and_return(true) }

    it 'processes the original request' do
      execute_request
      expect(app.requests.first).to have_attributes(path_info: URI(request_url).path)
    end

    it 'does not modify the original request method' do
      app.mock(request_url)
      execute_request
      expect(app.requests.first).to have_attributes(request_method: 'PATCH')
    end

    it 'persists changes during original request' do
      persisted = nil
      app.mock(request_url) { persisted = record.class.exists?(record.id) }

      expect { execute_request }.to change { persisted }.to(true)
    end

    it 'persists changes during preview request' do
      persisted = nil
      app.mock(request_url) { record }
      app.mock(preview_url) { persisted = record.class.exists?(record.id) }

      expect { execute_request(request_url) }.to change { persisted }.to(true)
    end

    it 'reverts changes at the end of the rehearsal' do
      record_id = nil
      app.mock(request_url) { record_id = record.id }
      execute_request

      expect(ActiveRecordMock.where(id: record_id)).not_to exist
    end

    context 'when the original request returns a 2xx' do
      before do
        app.mock(request_url, status: 200)
      end

      it 'serves a preview at the preview url' do
        execute_request
        expect(app.requests.last).to have_attributes(path_info: URI(preview_url).path)
      end

      it 'sets the preview request HTTP method to GET' do
        execute_request
        expect(app.requests.last).to have_attributes(request_method: 'GET')
      end

      it 'sets the params of the preview request from the preview_url' do
        preview_url = app.mock("/my/preview?success=true")
        request_url = app.mock("/pages/my_page?preview_url=#{CGI.escape(preview_url)}", status: 200)
        execute_request(request_url)

        expect(app.requests.last).to have_attributes(params: { 'success' => 'true' })
      end

      it 'clears the flash'
    end

    context 'when the original request returns a 3xx' do
      before do
        app.mock(request_url, status: 307, headers: { 'LOCATION' => redirect_url })
        app.mock(redirect_url)
      end

      let(:redirect_url) { '/some/redirect' }

      it 'serves the preview request' do
        execute_request(request_url)
        expect(app.requests.last).to have_attributes(path_info: preview_url)
      end

      it 'serves the redirect request when there is no preview_url' do
        request_url = app.mock('/my/page', status: 307, headers: { 'LOCATION' => redirect_url })
        execute_request(request_url)
        expect(app.requests.last).to have_attributes(path_info: redirect_url)
      end

      it 'clears the flash'
    end

    context 'when the original request returns a 4xx' do
      before do
        app.mock(request_url, status: 404)
      end

      it 'does not request the preview' do
        execute_request(request_url)
        expect(app.requests).not_to include(have_attributes(path_info: preview_url))
      end

      it 'reverts changes at the end of the rehearsal' do
        record_id = nil
        app.mock(request_url) { record_id = record.id }
        execute_request

        expect(ActiveRecordMock.where(id: record_id)).not_to exist
      end
    end

    context 'when the original request returns a 5xx' do
      before do
        app.mock(request_url, status: 500)
      end

      it 'does not request the preview' do
        execute_request(request_url)
        expect(app.requests).not_to include(have_attributes(path_info: preview_url))
      end

      it 'reverts changes at the end of the rehearsal' do
        record_id = nil
        app.mock(request_url) { record_id = record.id }
        execute_request

        expect(ActiveRecordMock.where(id: record_id)).not_to exist
      end
    end

    context 'when the preview request returns a 2xx' do
      before do
        app.mock(preview_url, status: 200)
      end

      it 'serves the preview request' do
        execute_request(request_url)
        expect(app.requests.last).to have_attributes(path_info: preview_url)
      end
    end

    context 'when the preview request returns a 3xx' do
      before do
        app.mock(preview_url, status: 307, headers: { 'LOCATION' => redirect_url1})
      end

      let(:redirect_url1) { '/redirect/1' }
      let(:redirect_url2) { '/redirect/2' }
      let(:redirect_url3) { '/redirect/3' }
      let(:final_url) { '/final' }

      it 'follows the redirect chain' do
        app.mock(redirect_url1, status: 307, headers: { 'LOCATION' => redirect_url2})
        app.mock(redirect_url2, status: 307, headers: { 'LOCATION' => redirect_url3})
        app.mock(redirect_url3, status: 307, headers: { 'LOCATION' => final_url})
        app.mock(final_url)

        execute_request(request_url)
        expect(app.requests.last).to have_attributes(path_info: final_url)
      end

      it 'raises an exception if a redirect chain contains a cycle' do
        app.mock(redirect_url1, status: 307, headers: { 'LOCATION' => redirect_url2})
        app.mock(redirect_url2, status: 307, headers: { 'LOCATION' => redirect_url3})
        app.mock(redirect_url3, status: 307, headers: { 'LOCATION' => redirect_url1})

        expect { execute_request(request_url) }.to raise_exception(Rehearsal::RedirectLoopError)
      end
    end

    context 'when the preview request returns a 4xx' do
      before do
        app.mock(preview_url, status: 404)
      end

      it 'serves the preview request' do
        execute_request(request_url)
        expect(app.requests.last).to have_attributes(path_info: preview_url)
      end
    end

    context 'when the preview request returns a 5xx' do
      before do
        app.mock(preview_url, status: 500)
      end

      it 'serves the preview request' do
        execute_request(request_url)
        expect(app.requests.last).to have_attributes(path_info: preview_url)
      end
    end
  end

  context 'outside of a rehearsal' do
    before { allow(Rehearsal::Configuration).to receive(:trigger).and_return(false) }

    it 'serves the original request' do
      execute_request
      expect(app.requests.last).to have_attributes(path_info: URI(request_url).path)
    end

    it 'does not process the preview request' do
      execute_request
      expect(app.requests).not_to include(path_info: preview_url)
    end

    it 'changes are not reverted at the end of the request' do
      record_id = nil
      app.mock(request_url) { record_id = record.id }
      execute_request

      expect(ActiveRecordMock.where(id: record_id)).to exist
    end
  end
end
