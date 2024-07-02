// import static org.junit.jupiter.api.Assertions.assertEquals;

// import org.junit.jupiter.api.Test;

public class Main {
  public static int[] birthday(int pop_size){

  int[] birthday = new int[pop_size]; 
    for(int j = 0; j < pop_size; j++)
      {
        birthday[j] = (int)(Math.random() * 365);
      }
    return birthday;
      //Great response time!
    //NICE! 
  }
public static int match(int pop_size){
  int[] bday = birthday(pop_size);
  for(int i = 0; i < pop_size - 1; i++)
  {
  for(int j = i + 1; j < pop_size; j++)
    {
      if(bday[i] == bday[j])
      {
        return 1;
      }
    }
  }
  return 0;
}
  public static double prob(int pop_size, int num_iters){
    double count = 0.0;
    for(int i = 0; i < num_iters; i++){
      count += match(pop_size);
    }
    return count / num_iters;
  }
  
  public static void main(String[] args) {
    int[] arr = birthday(25); 
    System.out.println(prob(23, 1000));
    System.out.println(match(25));
    for(int i = 0 ; i < arr.length; i++){
     //System.out.println(arr[i]);
    }

  }


  // @Test
  // void addition() {
  //     assertEquals(2, 1 + 1);
  // }
}