# frozen_string_literal: true
# Documentation: https://developer.github.com/webhooks/#repository-event
require 'safe_yaml/load'

class RepositoryEventJob < ApplicationJob
  queue_as :github_event

  YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m

  # rubocop:disable GuardClause
  def perform(payload_body)
    return unless payload_body['action'] == 'created'

    repository_id = payload_body['repository']['id']
    if (assignment_repo = AssignmentRepo.find_by(github_repo_id: repository_id))
      assignment = assignment_repo.assignment
      if (starter_code_repo_id = assignment.starter_code_repo_id)
        client = assignment.organization.github_client
        starter_code_issues = begin
          client.contents(starter_code_repo_id, path: '.github/classroom/issues')
        rescue Octokit::NotFound
          nil
        end

        # filter starter_code_issues to just .md files that start with a number
        starter_code_issues = starter_code_issues.select { |issue| issue[:type] == 'file' && issue[:path] =~ %r{\.github/classroom/issues/[0-9]+.*\.md} }

        return unless starter_code_issues.present?

        issue_files_contents = starter_code_issues.map do |issue_resource|
          issue_link = issue_resource[:_links][:self]
          encoded_issue_content = client.get(issue_link)[:content]
          Base64.decode64(encoded_issue_content)
        end

        issues = issue_files_contents.inject([]) do |issues, issue_file_contents|
          if issue_file_contents =~ YAML_FRONT_MATTER_REGEXP
            frontmatter = SafeYAML.load(Regexp.last_match(1))
            if frontmatter['title'].present?
              issues << {
                title: frontmatter['title'],
                labels: frontmatter['labels'],
                body: $POSTMATCH
              }
            end
          end
          issues
        end

        puts 'issues:'
        puts issues

        existing_issues = client.issues(repository_id, state: 'all')
        puts 'existing issues:'
        puts existing_issues
        puts 'endputses'

        # By checking existing_issues, this job is reentrant. So if some error
        # causes some issues not to be created, the classroom owner can
        # redeliver the webhook and it will create those issues without
        # duplicating the others (assuming the issue titles haven't changed)
        issues.each do |issue|
          next if existing_issues.find { |existing_issue| existing_issue[:title] == issue[:title] }
          client.create_issue(repository_id, issue[:title], issue[:body], issue)
        end
      end
    end
  end
  # rubocop:enable GuardClause
end
