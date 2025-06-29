# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LocallinkApi.Repo.insert!(%LocallinkApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias LocallinkApi.{Repo, User, Post, Accounts, Posts}

# Create sample users
{:ok, user1} = Accounts.create_user(%{
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  password: "password123",
  phone: "+998901234567",
  location: "Tashkent, Uzbekistan",
  skills: "Programming, Web Development",
  availability: "full-time"
})

{:ok, user2} = Accounts.create_user(%{
  first_name: "Jane",
  last_name: "Smith",
  email: "jane@example.com",
  password: "password123",
  phone: "+998907654321",
  location: "Samarkand, Uzbekistan",
  skills: "Graphic Design, Photography",
  availability: "part-time"
})

{:ok, user3} = Accounts.create_user(%{
  first_name: "Ali",
  last_name: "Karimov",
  email: "ali@example.com",
  password: "password123",
  phone: "+998909876543",
  location: "Bukhara, Uzbekistan",
  skills: "Plumbing, Electrical Work",
  availability: "weekends"
})

# Create sample posts
{:ok, _post1} = Posts.create_post(user1, %{
  title: "Need a plumber urgently",
  description: "My kitchen pipe is leaking and I need someone to fix it today. The leak is near the sink and water is everywhere.",
  category: "task",
  post_type: "seeking",
  location: "Chilanzar, Tashkent",
  urgency: "now",
  price: 150000,
  currency: "UZS",
  skills_required: "Plumbing",
  contact_preference: "phone"
})

{:ok, _post2} = Posts.create_post(user2, %{
  title: "Graphic Designer Available",
  description: "Professional graphic designer offering logo design, branding, and print materials. 5+ years experience.",
  category: "job",
  post_type: "offer",
  location: "Mirzo Ulugbek, Tashkent",
  urgency: "flexible",
  price: 200000,
  currency: "UZS",
  skills_required: "Graphic Design, Adobe Creative Suite",
  contact_preference: "app"
})

{:ok, _post3} = Posts.create_post(user3, %{
  title: "Weekend Football Game",
  description: "Looking for players to join our weekend football game in Alisher Navoi park. All skill levels welcome!",
  category: "event",
  post_type: "seeking",
  location: "Alisher Navoi Park, Tashkent",
  urgency: "this_week",
  contact_preference: "app"
})

{:ok, _post4} = Posts.create_post(user1, %{
  title: "Math Tutoring Services",
  description: "Experienced math teacher offering tutoring for high school and university students. Online and in-person available.",
  category: "job",
  post_type: "offer",
  location: "Yunusabad, Tashkent",
  urgency: "flexible",
  price: 100000,
  currency: "UZS",
  skills_required: "Mathematics, Teaching",
  contact_preference: "both"
})

{:ok, _post5} = Posts.create_post(user2, %{
  title: "Community Garden Cleanup",
  description: "Join us this Saturday for a community garden cleanup event. We'll provide tools and refreshments!",
  category: "event",
  post_type: "seeking",
  location: "Uzbekistan Ovozi Park, Tashkent",
  urgency: "tomorrow",
  contact_preference: "app"
})

IO.puts("Seeds completed! Created users and sample posts for LocalLink.")
IO.puts("You can now test the API with the sample data.")
IO.puts("API is available at: http://localhost:4000/api")
