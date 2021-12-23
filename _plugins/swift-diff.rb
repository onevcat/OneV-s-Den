  Jekyll::Hooks.register :site, :pre_render do |site|
    require "rouge"
  
    class SwiftDiff < Rouge::Lexers::Swift
      tag 'swift-diff'
      prepend :root do
        rule(/^\+.*$\n?/, Generic::Inserted)
        rule(/^-+.*$\n?/, Generic::Deleted)
        rule(/^!.*$\n?/, Generic::Strong)
        rule(/^@.*$\n?/, Generic::Subheading)
        rule(/^([Ii]ndex|diff).*$\n?/, Generic::Heading)
        rule(/^=.*$\n?/, Generic::Heading)
      end
    end
  end