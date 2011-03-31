Given /^I belong to a public workstream$/ do
  Given "a public workstream that I do not belong to"
  add_me_as_a_member_of projects.last
end

Given /^a public workstream that I do not belong to$/ do
  projects << project = new_public_project("[#{Time.now.to_i}] Any public workstream")  
end

Given /^there are more than (\d+) workstreams available$/ do |count|
  for i in 1..(count.to_i + 1) do
    projects << new_public_project("[#{Time.now.to_i}] Workstream (#{i})")        
  end
end

Given /a public workstream that is a child of another public workstream/ do
  projects << parent = new_public_project("[#{Time.now.to_i}] Parent")  
  projects << child = new_public_project("[#{Time.now.to_i}] Child")
  
  child.move_to_child_of parent
  child.parent_id.should(eql(parent.id), 
    "Failed to add project <#{child.name}> as child of <#{parent.name}>"
  ) 
end

Given /^I belong to a private workstream$/ do
  projects << new_private_project("[#{Time.now.to_i}] Someone else's private")
  
  add_me_as_a_member_of projects.last
end

Given /^a private workstream that I do not belong to$/ do
  projects << new_private_project("[#{Time.now.to_i}] Someone else's private")
end

Given /^the anonymous user is a member$/ do
  fail("No project yet, can't add anonymous as a member") unless projects.last
  add_as_member User.anonymous, projects.last
end

Then /^I see it$/ do; Then "it is visible"; end

Then /^I do not see it$/ do; Then "it is not visible"; end

Then /^it is(\snot)? visible$/ do |not_visible|
  show_or_not = not_visible ? "does not show" : "shows" 
  Then "it #{show_or_not} in the Latest Public Workstreams list"
  Then "it #{show_or_not} in the Most Active Public Workstreams list"
end

Then /^it shows in the Latest Public Workstreams list$/ do
  project_summary_selector = "div.splitcontentright"
    
  within project_summary_selector do |scope|  
    scope.should contain @projects.last.name
  end
end

Then /^it does not show in the Latest Public Workstreams list$/ do
  project_summary_selector = "div.splitcontentright"  
  
  has_project_summary = have_selector(project_summary_selector).matches?(response_body)
  
  if has_project_summary  
    within project_summary_selector do |scope|     
      scope.should_not contain @projects.last.name
    end
  end
end

Then /^it shows in the Most Active Public Workstreams list$/ do
  project_summary_selector = "div.splitcontentleft"
    
  within project_summary_selector do |scope|     
    scope.should contain @projects.last.name
  end
end

Then /^it does not show in the Most Active Public Workstreams list$/ do
  project_summary_selector = "div.splitcontentleft"
    
  within project_summary_selector do |scope|     
    scope.should_not contain @projects.last.name
  end
end

Then /I only see (\d+)/ do |expected_count|
  view = new_view
  view.latest_public_workstreams.size.should eql expected_count.to_i
  view.most_active_public_workstreams.size.should eql expected_count.to_i
end

def new_public_project(name); new_project name, true; end

def new_private_project(name); new_project name, false; end

def new_project(name, _public=false)
  result = Project.new
  result.name = name
  result.is_public = _public
  result.save!  
  result
end

def add_me_as_a_member_of(project); add_as_member @user, project; end

def add_as_member(user, project)
  project.members << Member.new(:user => user, :roles => [Role.administrator])
end

def projects 
  unless @projects
    @projects = []
    teardown { @projects.each {|project| project.delete} }
  end
  
  @projects
end

def new_view
  adapter = Webrat.adapter_class.new self
  BrowseBettermeansView.new Webrat::Session.new adapter
end